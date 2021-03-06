require 'singleton'
require 'renderer'
require 'concurrent/async'

class Player
  include Singleton
  include Concurrent::Async

  def initialize
    super

    @fps = 30.0
    @speed = 1.0
    @renderer = nil
    @running = false
    @strip = nil

    @led_count = ENV['LED_COUNT'].to_i

    if @led_count.nil? || ENV['GPIO_PIN'].nil?
      App.logger.warn 'LED_COUNT and/or GPIO_PIN not set in environment, putting player in sandbox mode'
    else

      require 'ws2812'

      begin
        App.logger.info "Initializing player with #{ENV['LED_COUNT']} leds on GPIO #{ENV['GPIO_PIN']}"
        @strip = Ws2812::Basic.new(@led_count, ENV['GPIO_PIN'].to_i)
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

    App.logger.info "Player running with target #{@fps} fps"

    t = 0

    begin
      frame = 0

      while frame < @fps
        start = Time.now

        led = 0

        while led < @led_count
          x = led.to_f / @led_count

          if @renderer
            (r, g, b) = @renderer.call(x, t)

            if @strip
              color = Ws2812::Color.new((255 * r).to_i, (255 * g).to_i, (255 * b).to_i)
              @strip[led] = color
            else
              Rails.logger.info "Rendering #{[r, g, b]}"
            end
          end
          led += 1
        end

        @strip.show if @strip

        duration = Time.now - start

        diff = (1.0 / @fps.to_f) - duration
        sleep(diff) if diff > 0

        t += (1.0 / @fps) * @speed

        t = 0.0 if t > 1.0

        frame += 1
      end
    end until @stop_requested

    @running = false
    App.logger.info 'Player stopped'
  end

  def play! render
    begin
      App.logger.info "Evaling new renderer #{render}"
      new_renderer = eval "Proc.new{|x,t| #{render} }"

      if new_renderer.is_a? Proc
        App.logger.info "Testing new renderer"
        begin
          new_renderer.call(0.0, 0.0)
          new_renderer.call(1.0, 1.0)

          @renderer = new_renderer
          App.logger.info "New renderer set"
        rescue Exception => e
          App.logger.warn "Error testing new renderer #{e.message}"
        end
      end
    rescue Exception => e
      App.logger.warn "Error evaling new renderer #{e.message}"
    end
  end

  def stop!
    @stop_requested = true

    App.logger.info "Requested player stop, waiting..."
  end

  def speed! speed
    App.logger.info "Setting new speed #{speed}"

    @speed = speed
  end
end
