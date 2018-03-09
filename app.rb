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
    $player.async.run!

    $store ||= Store.instance
    $store.load_all!
  end

  get '/player' do
    haml :player, format: :html5
  end

  get '/editor' do
    haml :editor, format: :html5
  end

  put '/play' do
    content_type 'application/json'

    renderer = params[:render]
    if renderer.nil?
      status 422
      return {error: 'missing required param: render'}.to_json
    end

    speedFactor = params[:speedFactor]

    validFloat = !!Float(speedFactor) rescue false
    if !validFloat || speedFactor.to_f < 0.0
      status 422
      return {error: 'invalid param: speedFactor'}.to_json
    end

    colors = params[:colors]

    $player.play! renderer
    $player.speed! speedFactor.to_f

    {message: 'ok'}.to_json
  end

  put '/speed' do
    content_type 'application/json'

    speedFactor = params[:speedFactor]

    validFloat = !!Float(speedFactor) rescue false
    if !validFloat || speedFactor.to_f < 0.0
      status 422
      return {error: 'invalid param: speedFactor'}.to_json
    end

    $player.speed! speedFactor.to_f

    {message: 'ok'}.to_json
  end

  post '/store' do
    content_type 'application/json'

    name = params[:name]
    unless name
      status 422
      return {error: 'missing required param: name'}.to_json
    end

    render = params['render']
    unless render
      status 422
      return {error: 'missing required param: render'}.to_json
    end

    $store.update! name, render

    {message: 'ok'}.to_json
  end

  put '/stop' do
    content_type 'application/json'

    $player.stop!

    {message: 'ok'}.to_json
  end

  get '/patterns' do
    content_type 'application/json'

    patterns = $store.patterns

    patterns.map(&:to_json).to_json
  end

  get '/' do
    redirect to('/player')
  end

  def self.logger
    $logger
  end

end
