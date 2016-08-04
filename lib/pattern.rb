require 'json'

class Pattern

  attr_accessor :name, :render

  def self.from_json pattern_json
    pattern = Pattern.new
    pattern.name = pattern_json['name']
    pattern.render = pattern_json['render']

    pattern
  end

  def to_json
    { name: name,
      render: render
    }
  end
end
