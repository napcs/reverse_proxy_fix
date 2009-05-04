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
  
  #it "should deactivate optimised routes" do
  #  ActionController::Base::optimise_named_routes.should be_false
  #end
  
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
      pending "BASE_URL allowed as Hash of host, protocol, port, and path"
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
    
    it "should include BASE_URL in the request uri" do
      @request.set_REQUEST_URI "/path/of/some/uri"
      @request.request_uri.should eql("#{BASE_URL}/path/of/some/uri")

      @request.set_REQUEST_URI "/"
      @request.request_uri.should eql("#{BASE_URL}/")
    end
    
    it "should not include BASE_URL in the request path" do
      @request.set_REQUEST_URI "/path/of/some/uri"
      @request.path.should eql("/path/of/some/uri")

      @request.set_REQUEST_URI "/"
      @request.path.should eql("/")
    end
    
    it "should return the correct request url" do
      @request.set_REQUEST_URI "/path/of/some/uri"
      @request.url.should eql("#{BASE_URL}/path/of/some/uri")

      @request.set_REQUEST_URI "/"
      @request.url.should eql("#{BASE_URL}/")
    end
  end 
  
  context "route recognition" do
    before(:all) do
      ActionController::Base.optimise_named_routes = true
      @rs = ::ActionController::Routing::RouteSet.new
      
      ActionController::Routing.use_controllers! %w(content admin/user admin/news_feed)
    end
    
    it "should recognise routes that include BASE_URL" do
      @rs.draw {|m| m.connect ':controller/:action/:id' }
      
      @rs.recognize_path("#{BASE_URL}/content").should ==({:controller => "content", :action => 'index'})
      @rs.recognize_path("#{BASE_URL}/content/list").should ==({:controller => "content", :action => 'list'})
      @rs.recognize_path("#{BASE_URL}/content/show/10").should ==({:controller => "content", :action => 'show', :id => '10'})
      @rs.recognize_path("#{BASE_URL}/admin/user/show/10").should ==({:controller => "admin/user", :action => 'show', :id => '10'})
  
      @rs.generate(:controller => 'admin/user', :action => 'show', :id => 10).should ==('/admin/user/show/10')
      
      @rs.generate({:action => 'show'}, {:controller => 'admin/user', :action => 'list', :id => '10'}).should ==('/admin/user/show')
      @rs.generate({}, {:controller => 'admin/user', :action => 'list', :id => '10'}).should ==('/admin/user/list/10')
      
      @rs.generate({:controller => 'stuff'}, {:controller => 'admin/user', :action => 'list', :id => '10'}).should ==('/admin/stuff')
      @rs.generate({:controller => '/stuff'}, {:controller => 'admin/user', :action => 'list', :id => '10'}).should ==('/stuff')
    end
  end
end
