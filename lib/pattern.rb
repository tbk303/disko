require 'json'
require 'v8'

class Pattern

  attr_accessor :name, :frames, :function

  def self.from_json pattern_json
    pattern = Pattern.new
    pattern.name = pattern_json['name']
    pattern.frames = pattern_json['frames']
    pattern.function = pattern_json['function']

    pattern
  end

  def generate_frames
    App.logger.info "Generating frames for #{name}"

    v8 = V8::Context.new
    v8.eval "var func = #{function}"

    frame_count = 25
    led_count = ENV['LED_COUNT'].to_i
    leds = (0...led_count)

    self.frames = (0...frame_count).map do |frame|
      leds.map do |led|
        rgb = v8[:func].f(frame.to_f / frame_count, led.to_f / led_count)
        rgb.map {|v| (v * 255).to_i }
      end.flatten
    end
  end

  def to_json
    { name: name,
      frames: frames,
      function: function
    }.to_json
  end
end
