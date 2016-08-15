require 'singleton'
require 'ws2812'
require 'renderer'

class Player
  include Singleton

  def initialize
    super

    @writer = nil

    @pid = nil

    @fps = 30.0
  end

  def run!
    reader, @writer = IO.pipe

    @pid = fork do
      @writer.close

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

      renderer = nil
      speed = 1.0

      thread = Thread.new do
        App.logger.info "Player running with target #{@fps} fps"

        loop do
          (0...@fps).each do |frame|
            start = Time.now

            t = frame.to_f / @fps

            (0...led_count).each do |led|
              x = led.to_f / led_count

              if renderer
                r, g, b = renderer(x, t)

                if strip
                  color = Ws2812::Color.new((255 * r).to_i, (255 * g).to_i, (255 * b).to_i)
                  strip[led] = color
                else
                  Rails.logger.info "Rendering #{[r, g, b]}"
                end
              end
            end

            strip.show if strip

            duration = Time.now - start

            diff = (1.0 / @fps.to_f) - duration
            sleep(diff) if diff > 0
          end
        end
      end

      stop_requested = false

      begin
        message = reader.gets

        App.logger.info "Received message #{message}"

        case message
        when ':stop:'
          stop_requested = true
        when /:speed: (\d+)/
          new_speed = $1
          speed = new_speed / 10.0
        else
          new_renderer = eval "Proc.new{|x,t|\n #{message.gsub('\n', "\n")} \n}"

          if new_renderer.is_a? Proc
            renderer = new_renderer
          end
        end

      end until stop_requested

      thread.exit
      strip.close if strip

      App.logger.info 'Player stopped'
    end

    App.logger.info "Player running with PID #{@pid}"

    reader.close
  end

  def play! render
    unless @writer
      App.logger.info "Cannot play pattern #{pattern.name}, pipe not ready"
      return
    end

    App.logger.info "Playing new pattern"
    @writer.puts render.gsub("\n", '\n')
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

  def speed! speed
    unless @writer
      App.logger.info 'Cannot set speed, pipe not ready'
      return
    end

    App.logger "Setting new speed #{speed}"
    @write.puts ":speed: #{(speed * 10).round}"
  end
end
