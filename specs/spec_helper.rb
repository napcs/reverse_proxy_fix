begin
  require File.dirname(__FILE__) + '/../../../../spec/spec_helper'
rescue LoadError
  RAILS_ENV = "test"
  require 'rubygems'
  gem 'actionpack', "=2.3.2"
  gem 'rspec'
  #gem 'rspec-rails'
  require 'action_controller'
  require 'action_controller/test_process'
  require 'spec'
  #require 'spec/rails'
end

include ActionController::UrlWriter
ActionController::Routing::Routes.reload rescue nil

plugin_spec_dir = File.dirname(__FILE__)
ActionController::Base.logger = Logger.new(plugin_spec_dir + "/debug.log")

class MockController
  attr_accessor :routes

  def initialize(routes)
    self.routes = routes
  end

  def url_for(options)
    only_path = options.delete(:only_path)

    port        = options.delete(:port) || 80
    port_string = port == 80 ? '' : ":#{port}"

    protocol = options.delete(:protocol) || "http"
    host     = options.delete(:host) || "test.host"
    anchor   = "##{options.delete(:anchor)}" if options.key?(:anchor)

    path = routes.generate(options)

    only_path ? "#{path}#{anchor}" : "#{protocol}://#{host}#{port_string}#{path}#{anchor}"
  end

  def request
    @request ||= ActionController::TestRequest.new
  end
end

def setup_for_named_route(rs)
  klass = Class.new(MockController)
  rs.install_helpers(klass)
  klass.new(rs)
end

