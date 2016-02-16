require 'json'

class Pattern

  attr_accessor :name, :frames, :function

  def self.from_json pattern_json
    pattern = Pattern.new
    pattern.name = pattern_json['name']
    pattern.frames = pattern_json['frames']
    pattern.function = pattern_json['function']

    pattern
  end

  def ensure_frames
    if frames.nil?
    end
  end

  def to_json
    { name: name,
      frames: frames,
      function: function
    }.to_json
  end
end
