require 'json'
require 'sinatra/base'

module Disko
  class Veejay < Sinatra::Base
    def self.write_frames(name, fps, function_string)
      o = Object.new
      o.instance_eval "def f(t,x); #{function_string}; end"
      frame_count = 20
      led_count = 240
      leds = (0...led_count)
      frames = (0...frame_count).map do |frame|
        leds.map do |led|
          o.f(frame/frame_count, led/led_count).map {|v| (v * 255).to_i }
        end.flatten
      end
      hash = {frames: frames}
      File.open(Path.join(ENV['DISKO_DIR'], name),"w") do |f|
        f.write(hash.to_json)
      end

    end

    get '/new' do
     #f1 = "[(Math.sin(t * Math::PI + (x * Math::PI)) + 1.0) / 2,  (Math.cos(t * 3.14 + (x * Math::PI)) + 1.0) / 2.0, t]"
     #'http://localhost:4567/new?name=bar&function=%5B(Math.sin(t%20*%20Math%3A%3API%20%2B%20(x%20*%20Math%3A%3API))%20%2B%201.0)%20%2F%202%2C%20%20(Math.cos(t%20*%203.14%20%2B%20(x%20*%20Math%3A%3API))%20%2B%201.0)%20%2F%202.0%2C%20t%5D'
     self.class.write_frames(params['name'], 20, params['function'])
     "OK"
    end

    # start the server if ruby file executed directly
    run! if app_file == $0
  end
end
