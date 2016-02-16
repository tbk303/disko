require 'bundler'

Bundler.require(:default)

$:.unshift(File.expand_path('../lib', __FILE__))
$:.unshift(File.expand_path('../vendor/ws2812/lib', __FILE__))

require './app'

run App
