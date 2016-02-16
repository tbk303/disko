require 'json'
require 'singleton'
require 'concurrent/async'

class Store
  include Singleton
  include Concurrent::Async

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

  def add! pattern
    pattern.ensure_frames

    @patterns << pattern

    file_name = "#{pattern.name.downcase.gsub(/[^0-9a-z ]/i, '')}.json"

    File.open(File.join(ENV['DISKO_DIR'], file_name), 'w') do |file|
      file.write pattern.to_json
    end
  end

end
