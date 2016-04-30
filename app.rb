require 'logger'
require 'json'

require 'player'
require 'store'
require 'pattern'

class App < Sinatra::Base

  VERSION = '0.1'

  configure do
    raise 'DISKO_DIR not set or missing' if ENV['DISKO_DIR'].nil? || !File.exists?(ENV['DISKO_DIR'])

    enable :logging

    $logger = Logger.new STDOUT
    $logger.level = Logger::DEBUG
    set :logger, $logger

    $player ||= Player.instance
    $player.run!

    $store ||= Store.instance
    $store.load_all!
  end

  get '/player' do
    haml :player, format: :html5
  end

  get '/editor' do
    haml :editor, format: :html5
  end

  put '/play/:name' do
    content_type 'application/json'

    name = params[:name]
    if name.nil?
      status 422
      return {error: 'missing required param: name'}.to_json
    end

    pattern = $store.find_by_name name
    unless pattern
      status 404
      return {error: "unknown pattern: #{name}"}.to_json
    end

    $player.play! pattern

    {message: 'ok'}.to_json
  end

  post '/store' do
    content_type 'application/json'

    name = params[:name]
    unless name
      status 422
      return {error: 'missing required param: name'}.to_json
    end

    function = params[:function]
    unless function
      status 422
      return {error: 'missing required param: function'}.to_json
    end

    $store.async.update! name, function

    {message: 'ok'}.to_json
  end

  get '/patterns' do
    content_type 'application/json'

    patterns = $store.patterns

    patterns.map{|p| {name: p.name, function: p.function}}.to_json
  end

  get '/' do
    redirect to('/player')
  end

  def self.logger
    $logger
  end

end
