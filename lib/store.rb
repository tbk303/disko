require 'json'
require 'singleton'

class Store
  include Singleton

  def initialize
    super
  end

  def load_all!
    @patterns = []

    Dir.glob(File.join ENV['DISKO_DIR'], '*.json') do |file|
      begin
        pattern_json = JSON.parse(File.read file)

        @patterns << Pattern.from_json(pattern_json)

      rescue JSON::ParserError
        App.logger.warn "Unable to load pattern from #{file}"
      end
    end

    App.logger.info "Loaded #{@patterns.length} patterns"
  end

  def patterns
    @patterns
  end

  def find_by_name name
    @patterns.find do |pattern|
      pattern.name == name
    end
  end

  def update! name, function_js, function_rb
    App.logger.info "Storing pattern #{name}"

    existing_pattern = find_by_name name

    if existing_pattern
      pattern = existing_pattern
    else
      pattern = Pattern.new
      @patterns << pattern
    end

    pattern.name = name
    pattern.function_js = function_js
    pattern.function_rb = function_rb

    file_name = "#{pattern.name.downcase.gsub(/[^0-9a-z ]/i, '')}.json"

    File.open(File.join(ENV['DISKO_DIR'], file_name), 'w') do |file|
      file.write pattern.to_json
    end

    App.logger.info "Pattern #{name} stored"
  rescue Exception => e
    App.logger.info e.message
    App.logger.info e.backtrace
  end

end
