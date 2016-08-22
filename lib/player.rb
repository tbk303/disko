require 'singleton'
require 'renderer'

class Player
  include Singleton

  def initialize
    super

    @fps = 30.0
    @speed = 1.0
    @renderer = nil
    @running = false
    @strip = nil

    @led_count = ENV['LED_COUNT']

    if @led_count.nil? || ENV['GPIO_PIN'].nil?
      App.logger.warn 'LED_COUNT and/or GPIO_PIN not set in environment, putting player in sandbox mode'
    else

      require 'ws2812'

      begin
        App.logger.info "Initializing player with #{ENV['LED_COUNT']} leds on GPIO #{ENV['GPIO_PIN']}"
        @strip = Ws2812::Basic.new(@led_count)
        @strip.open
        @strip.brightness = 255
      rescue Exception => e
        App.logger.warn "Error initializing player: #{e.message}"
        @strip = nil
      end
    end
  end

  def running?
    @running
  end

  def run!
    return if running?

    @running = true
    @stop_requested = false

    thread = Thread.new do
      App.logger.info "Player running with target #{@fps} fps"

      begin
        (0...@fps).each do |frame|
          start = Time.now

          t = frame.to_f / @fps

          (0...@led_count).each do |led|
            x = led.to_f / @led_count

            if @renderer
              r, g, b = @renderer.call(x, t)

              if @strip
                color = Ws2812::Color.new((255 * r).to_i, (255 * g).to_i, (255 * b).to_i)
                @strip[led] = color
              else
                Rails.logger.info "Rendering #{[r, g, b]}"
              end
            end
          end

          @strip.show if @strip

          duration = Time.now - start

          diff = (1.0 / @fps.to_f) - duration
          sleep(diff) if diff > 0
        end
      end until @stop_requested

      @running = false
      App.logger.info 'Player stopped'
    end
  end

  def play! render
    begin
      new_renderer = eval "Proc.new{|x,t|\n #{render} \n}"
      @renderer = new_renderer
      App.logger.info "Playing new renderer"
    rescue
      App.logger.warn "Error evaling new renderer"
    end
  end

  def stop!
    @stop_requested = true

    App.logger.info "Requested player stop, waiting..."
  end

  def speed! speed
    App.logger "Setting new speed #{speed}"

    @speed = speed
  end
end
