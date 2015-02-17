require 'selenium-webdriver'
require 'nokogiri'
require 'logger'
require 'active_record'
require 'active_support'
require 'yaml'
require 'open-uri'
require 'forwardable'
require 'byebug'

require_relative './lib/web_bot.rb'

Bundler.require

::Moped::BSON = ::BSON

Dir.glob('./tasks/*.rake').each { |r| load r }
Dir.glob('./config/initializers/*.rb').each { |file| require file }
Dir.glob('./models/*.rb').sort.each { |file| require file }