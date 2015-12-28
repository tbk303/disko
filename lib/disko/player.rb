require 'ws2812'
require 'listen'
require 'json'

module Disko

  class Player

    def self.run!

      disko_dir = ENV['DISKO_DIR']

      raise "DISKO_DIR does not exist/is not configured" unless (disko_dir && Dir.exists?(disko_dir))

      puts "Using #{disko_dir}"

      strip = Ws2812::Basic.new(240, 18)
      strip.open

      puts "Strip initialized"

      begin
        strip.brightness = 255

        ws_frames = []

        listener = Listen.to(ENV['DISKO_DIR']) do |modified, added, _|

          new_file_path = (modified + added).first
          puts "Detected new file #{new_file_path}"

          if new_file_path

            begin

              rgb_frames = JSON.parse(File.read(new_file_path))["frames"]
              raise "Expecting JSON arrays" unless rgb_frames.is_a? Array

              puts "Loaded #{rgb_frames.length} frames"

              ws_frames = rgb_frames.map do |rgb_frame|
                rgb_frame.each_slice(3).map{|r, g, b| Ws2812::Color.new(r,g,b) }
              end
            rescue JSON::ParserError
              puts "Unable to read #{new_file_path}"
            end
          end
        end

        listener.start

        loop do
          ws_frames.each do |ws_frame|
            ws_frame.each_with_index do |color, index|
              strip[index] = color
            end

            strip.show

            sleep (1.0 / 25.0)
          end
        end

      ensure
        puts "Shutting down"

        strip.close
      end
    end
  end
end
