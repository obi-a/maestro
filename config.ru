#config.ru
begin
  require 'rubygems'
  require "bundler/setup"

  require "bugsnag"

  Bugsnag.configure do |config|
    config.api_key = ENV["BUGSNAG_API_KEY"]
  end

  dir = Pathname(__FILE__).dirname.expand_path
  require dir + 'config'
  require dir + 'lib/ragios/rest_server'

  run App

  def require_all(path)
    Dir.glob(File.dirname(__FILE__) + path + '/*.rb') do |file|
      require File.dirname(__FILE__)  + path + '/' + File.basename(file, File.extname(file))
    end
  end

  require_all '/initializers'
rescue => e
  $stderr.puts '-' * 80
  $stderr.puts "Application Error: #{e.class}: '#{e.message}'"
  $stderr.puts e.backtrace.join("\n")
  $stderr.puts '-' * 80
  raise e
end
