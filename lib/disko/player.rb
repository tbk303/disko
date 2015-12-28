require 'ws2812'
require 'listen'
require 'json'

module Disko

  class Player

    def run

      raise "DISKO_DIR does not exist/is not configured" unless Dir.exists? ENV['DISKO_DIR']

      strip = Ws2812::Basic.new(240, 18)
      strip.open

      begin
        strip.brightness = 255

        listener = Listen.to(ENV['DISKO_DIR']) do |modified, added, _|

          new_file_path = (modified || added).first

          if new_file_path

            begin

              rgb_frames = JSON.parse new_file_path

              raise "Expecting JSON arrays" unless rgbs.is_a? Array

              ws_frames = rgb_frames.map do |rgb_frame|
                rgb_frame.each_slice(3).map{|r, g, b| Ws2812::Color.new(r,g,b) }
              end

              loop do
                ws_frames.each do |ws_frame|
                  ws_frame.each_with_index do |color, index|
                    strip[index] = color
                  end

                  strip.show

                  sleep (1.0 / 25.0)
                end
              end

            rescue JSON::ParserError
            end
          end
        end

      ensure
        strip.close
      end
    end
  end
end
