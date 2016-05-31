require 'json'

class Pattern

  attr_accessor :name, :render_rb, :render_js

  def self.from_json pattern_json
    pattern = Pattern.new
    pattern.name = pattern_json['name']
    pattern.render_js = pattern_json['render_js'] || pattern_json['function']
    pattern.render_rb = pattern_json['render_rb']

    pattern
  end

  def to_json
    { name: name,
      render_js: render_js,
      render_rb: render_rb
    }
  end
end
