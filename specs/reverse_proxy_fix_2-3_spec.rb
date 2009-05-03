require File.dirname(__FILE__) + '/spec_helper'
require File.join(File.dirname(__FILE__), '..', 'lib',  '23')

describe "when BASE_URL is set" do
  before(:each) do
    unless Object.const_defined? 'BASE_URL'
      Object.const_set('BASE_URL', 'http://www.foo.com/bar') 
      ActionController.reset_asset_host_and_route_optimization
    end
  end
  
  it "should return true on check mode and base" do
    ActionController.check_mode_and_base.should be_true
  end
  
  it "should set the base asset host to BASE_URL" do
    ActionController::Base.asset_host.should eql(BASE_URL)
  end
  
  it "should deactivate optimised routes" do
    ActionController::Base::optimise_named_routes.should be_false
  end
  
  context "url writing and rewriting" do
    before(:each) do
      @request = ActionController::TestRequest.new
      @params = {
        #:skip_relative_url_root => nil,
        #:only_path      => nil,
        #:protocol       => nil,
        #:host           => nil,
        #:port           => nil,
        #:user           => nil,
        #:password       => nil,
        #:trailing_slash => nil
        :controller => 'c',
        :action     => 'a',
        :id         => 'i'
      }
      @rewriter = ActionController::UrlRewriter.new(@request, @params)
    end
    
    it "should prepend BASE_URL to rewritten url" do
      @rewriter.rewrite(@params).should eql("#{BASE_URL}/c/a/i")
    end
    
    it "should ignore :protocol" do
      @rewriter.rewrite(@params.merge(:protocol => "ftp")).should eql("#{BASE_URL}/c/a/i")
    end
    
    it "should ignore :host" do
      @rewriter.rewrite(@params.merge(:host => "test.com")).should eql("#{BASE_URL}/c/a/i")
    end
    
    it "should ignore :port" do
      @rewriter.rewrite(@params.merge(:port => "99")).should eql("#{BASE_URL}/c/a/i")
    end
    
    it "should respect :user and :password" do
      @rewriter.rewrite(@params.merge(:user => "dave", :password => "d4ve")).should eql("http://dave:d4ve@www.foo.com/bar/c/a/i")
    end
    
    it "should respect :trailing_slash" do
      @rewriter.rewrite(@params.merge(:trailing_slash => true)).should eql("#{BASE_URL}/c/a/i/")
    end
    
    it "should respect :only_path" do
      pending
      @rewriter.rewrite(@params.merge(:only_path => true)).should eql("/bar/c/a/i")
    end
    
    it "should respect :skip_relative_url_root" do
      @rewriter.rewrite(@params.merge(:only_path => true)).should eql("/c/a/i")
    end
  end
  
  context "request parsing" do
    before(:each) do
      @request = ActionController::TestRequest.new
      ActionController::Base.relative_url_root = nil
    end
    
    it "should return the full url for the request uri" do
      @request.env['SERVER_SOFTWARE'] = 'Apache 42.342.3432'
      
      @request.set_REQUEST_URI "http://www.rubyonrails.org/path/of/some/uri?mapped=1"
      @request.request_uri.should eql('/path/of/some/uri?mapped=1')
      @request.path.should eql('/path/of/some/uri')
      
      @request.set_REQUEST_URI "http://www.rubyonrails.org/path/of/some/uri"
      @request.request_uri.should eql("/path/of/some/uri")
      @request.path.should eql("/path/of/some/uri")
      
      @request.set_REQUEST_URI "/path/of/some/uri"
      @request.request_uri.should eql("/path/of/some/uri")
      @request.path.should eql("/path/of/some/uri")
      
      @request.set_REQUEST_URI "/"
      @request.request_uri.should eql("/")
      @request.path.should eql("/")
      
      @request.set_REQUEST_URI "/?m=b"
      @request.request_uri.should eql("/?m=b")
      @request.path.should eql("/")
      
      @request.set_REQUEST_URI "/"
      @request.env['SCRIPT_NAME'] = "/dispatch.cgi"
      @request.request_uri.should eql("/")
      @request.path.should eql("/")
      
      ActionController::Base.relative_url_root = "/hieraki"
      @request.set_REQUEST_URI "/hieraki/"
      @request.env['SCRIPT_NAME'] = "/hieraki/dispatch.cgi"
      @request.request_uri.should eql("/hieraki/")
      @request.path.should eql("/")
      ActionController::Base.relative_url_root = nil
      
      ActionController::Base.relative_url_root = "/collaboration/hieraki"
      @request.set_REQUEST_URI "/collaboration/hieraki/books/edit/2"
      @request.env['SCRIPT_NAME'] = "/collaboration/hieraki/dispatch.cgi"
      @request.request_uri.should eql("/collaboration/hieraki/books/edit/2")
      @request.path.should eql("/books/edit/2")
      ActionController::Base.relative_url_root = nil
      
      # The following tests are for when REQUEST_URI is not supplied (as in IIS)
      @request.env['PATH_INFO'] = "/path/of/some/uri?mapped=1"
      @request.env['SCRIPT_NAME'] = nil #"/path/dispatch.rb"
      @request.set_REQUEST_URI nil
      @request.request_uri.should eql("/path/of/some/uri?mapped=1")
      @request.path.should eql("/path/of/some/uri")
      
      ActionController::Base.relative_url_root = '/path'
      @request.env['PATH_INFO'] = "/path/of/some/uri?mapped=1"
      @request.env['SCRIPT_NAME'] = "/path/dispatch.rb"
      @request.set_REQUEST_URI nil
      @request.request_uri.should eql("/path/of/some/uri?mapped=1")
      @request.path.should eql("/of/some/uri")
      ActionController::Base.relative_url_root = nil
      
      @request.env['PATH_INFO'] = "/path/of/some/uri"
      @request.env['SCRIPT_NAME'] = nil
      @request.set_REQUEST_URI nil
      @request.request_uri.should eql("/path/of/some/uri")
      @request.path.should eql("/path/of/some/uri")
      
      @request.env['PATH_INFO'] = "/"
      @request.set_REQUEST_URI nil
      @request.request_uri.should eql("/")
      @request.path.should eql("/")
      
      @request.env['PATH_INFO'] = "/?m=b"
      @request.set_REQUEST_URI nil
      @request.request_uri.should eql("/?m=b")
      @request.path.should eql("/")
      
      @request.env['PATH_INFO'] = "/"
      @request.env['SCRIPT_NAME'] = "/dispatch.cgi"
      @request.set_REQUEST_URI nil
      @request.request_uri.should eql("/")
      @request.path.should eql("/")
      
      ActionController::Base.relative_url_root = '/hieraki'
      @request.env['PATH_INFO'] = "/hieraki/"
      @request.env['SCRIPT_NAME'] = "/hieraki/dispatch.cgi"
      @request.set_REQUEST_URI nil
      @request.request_uri.should eql("/hieraki/")
      @request.path.should eql("/")
      ActionController::Base.relative_url_root = nil
      
      @request.set_REQUEST_URI '/hieraki/dispatch.cgi'
      ActionController::Base.relative_url_root = '/hieraki'
      @request.path.should eql("/dispatch.cgi")
      ActionController::Base.relative_url_root = nil
      
      @request.set_REQUEST_URI '/hieraki/dispatch.cgi'
      ActionController::Base.relative_url_root = '/foo'
      @request.path.should eql("/hieraki/dispatch.cgi")
      ActionController::Base.relative_url_root = nil
      
      # This test ensures that Rails uses REQUEST_URI over PATH_INFO
      ActionController::Base.relative_url_root = nil
      @request.env['REQUEST_URI'] = "/some/path"
      @request.env['PATH_INFO'] = "/another/path"
      @request.env['SCRIPT_NAME'] = "/dispatch.cgi"
      @request.request_uri.should eql("/some/path")
      @request.path.should eql("/some/path")
    end
  end 
  
  #
  # TODO: port tests from Rails
  # 
  #context "route recognition" do
  #  # ActionController::Routing::Routes.draw do |map|
  #  # end  
  #  #ensure
  #  #ActionController::Routing::Routes.load!
  #  
  #  it "should recognise routes that include BASE_URL"
  #end
  #
  #context "caching" do
  #  it "should provide the path key for page caching"
  #  
  #  # TODO: page, action, and fragment caching keys
  #  
  #  #def test_page_caching_resources_saves_to_correct_path_with_extension_even_if_default_route
  #  #  @params[:format] = 'rss'
  #  #  assert_equal '/posts.rss', @rewriter.rewrite(@params)
  #  #  @params[:format] = nil      
  #  #  assert_equal '/', @rewriter.rewrite(@params)
  #  #end
  #  
  #  #def test_should_cache_with_custom_path
  #  #  get :custom_path
  #  #  assert File.exist?("#{FILE_STORE_PATH}/index.html")
  #  #end
  #
  #  #def test_should_expire_cache_with_custom_path                                        d
  #  #  get :custom_path
  #  #  assert File.exist?("#{FILE_STORE_PATH}/index.html")
  #  #                                                                                     ribe "when BASE_URL is not set" do
  #  #  get :expire_custom_path                                                            fore(:each) do
  #  #  assert !File.exist?("#{FILE_STORE_PATH}/index.html")                               # TODO: unset BASE_URL
  #  #end                                                                                  d
  #  #
  #  #def test_should_cache_without_trailing_slash_on_url
  #  #  @controller.class.cache_page 'cached content', '/page_caching_test/trailing_slash'
  #  #  assert File.exist?("#{FILE_STORE_PATH}/page_caching_test/trailing_slash.html")
  #  #end
  #  #
  #  #def test_should_cache_with_trailing_slash_on_url
  #  #  @controller.class.cache_page 'cached content', '/page_caching_test/trailing_slash/'
  #  #  assert File.exist?("#{FILE_STORE_PATH}/page_caching_test/trailing_slash.html")
  #  #end
  #  #
  #  #def test_should_cache_ok_at_custom_path
  #  #  @request.stubs(:path).returns("/index.html")
  #  #  get :ok
  #  #  assert_response :ok
  #  #  assert File.exist?("#{FILE_STORE_PATH}/index.html")
  #  #end
  #end
end
