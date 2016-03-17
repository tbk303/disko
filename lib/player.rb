require 'singleton'
require 'concurrent/async'
require 'ws2812'

class Player
  include Singleton
  include Concurrent::Async

  def initialize
    super

    @running = false
    @frames = nil
    @fps = 25.0

    if ENV['LED_COUNT'].nil? || ENV['GPIO_PIN'].nil?
      App.logger.warn 'LED_COUNT and/or GPIO_PIN not set in environment, putting player in sandbox mode'
      @strip = nil
    else
      begin
        App.logger.info "Initializing player with #{ENV['LED_COUNT']} leds on GPIO #{ENV['GPIO_PIN']}"
        @strip = Ws2812::Basic.new(ENV['LED_COUNT'].to_i, ENV['GPIO_PIN'].to_i)
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
    unless running?
      @running = true
      @stop_requested = false

      App.logger.info 'Player running'

      loop do
        @frames.each do |frame|
          if @strip
            App.logger.info '.'
            frame.each_with_index do |color, index|
              @strip[index] = color
            end

            @strip.show
          end

          sleep(1.0 / @fps.to_f)

          break if @stop_requested
        end
      end

      @running = false

      App.logger.info 'Player stopped'
    end
  end

  def play! pattern
    @frames = pattern.frames.map do |rgb_frame|
      rgb_frame.each_slice(3).map{|r, g, b| Ws2812::Color.new(r,g,b) }
    end

    App.logger.info "Playing pattern #{pattern.name}"
  end

  def stop!
    @stop_requested = true

    App.logger.info "Requested player stop"
  end

  def fps= fps
    @fps = fps
  end
end
