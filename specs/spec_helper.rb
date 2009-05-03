begin
  require File.dirname(__FILE__) + '/../../../../spec/spec_helper'
rescue LoadError
  RAILS_ENV="test"
  require 'rubygems'
  gem 'actionpack', "=2.3.2"
  gem 'rspec'
  #gem 'rspec-rails'
  require 'action_controller'
  require 'action_controller/test_process'
  require 'spec'
  #require 'spec/rails'
end

plugin_spec_dir = File.dirname(__FILE__)
ActionController::Base.logger = Logger.new(plugin_spec_dir + "/debug.log")

