require 'json'

class Pattern

  attr_accessor :name, :function

  def self.from_json pattern_json
    pattern = Pattern.new
    pattern.name = pattern_json['name']
    pattern.function = pattern_json['function']

    pattern
  end

  def to_json
    { name: name,
      function: function
    }.to_json
  end
end
