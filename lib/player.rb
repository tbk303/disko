require 'singleton'
require 'ws2812'
require 'v8'

class Player
  include Singleton

  def initialize
    super

    @writer = nil

    @pid = nil

    @fps = 25.0
  end

  def run!
    reader, @writer = IO.pipe

    @pid = fork do
      @writer.close

      stop_requested = false

      if ENV['LED_COUNT'].nil? || ENV['GPIO_PIN'].nil?
        App.logger.warn 'LED_COUNT and/or GPIO_PIN not set in environment, putting player in sandbox mode'
        strip = nil
      else
        begin
          App.logger.info "Initializing player with #{ENV['LED_COUNT']} leds on GPIO #{ENV['GPIO_PIN']}"
          strip = Ws2812::Basic.new(ENV['LED_COUNT'].to_i, ENV['GPIO_PIN'].to_i)
          strip.open
          strip.brightness = 255
        rescue Exception => e
          App.logger.warn "Error initializing player: #{e.message}"
          strip = nil
        end
      end

      led_count = ENV['LED_COUNT'].to_i

      last_message = nil
      v8 = nil

      begin
        App.logger.info 'Player running'

        readables, _, = IO.select [reader]

        if readables.any?
          new_message = readables.first.gets
        end

        if new_message != last_message
          last_message = new_message

          App.logger.info "New message received: #{last_message}"

          if last_message == ':stop:'
            stop_requested = true
          else
            v8 = V8::Context.new
            v8.eval "var func = #{last_message}"
          end
        end

        (0...@fps).each do |frame|
          if v8
            (0...led_count).each do |led|
              rgb = v8[:func].f(frame.to_f / @fps, led.to_f / led_count)
              r, g, b = rgb.map {|v| (v * 255).to_i }

              if @strip
                color = Ws2812::Color.new(r,g,b)
                @strip[led] = color
              end
            end
          end

          @strip.show if @strip
          sleep(1.0 / @fps.to_f)
        end

      end until stop_requested

      App.logger.info 'Player stopped'
    end

    reader.close
  end

  def play! pattern
    unless @writer
      App.logger.info "Cannot play pattern #{pattern.name}, pipe not ready"
      return
    end

    App.logger.info "Playing pattern #{pattern.name}"
    @writer.puts pattern.function.delete("\n")
  end

  def stop!
    unless @writer
      App.logger.info "Cannot stop player, pipe not ready"
      return
    end

    App.logger.info "Requested player stop, waiting..."
    @write.puts ':stop:'

    Process.waitpid @pid

    @pid = nil
    @write = nil
    App.logger.info "Player stopped"
  end
end
