# Reverse proxy fix for Rails 2.3
#
# TODO: allow BASE_URL to be String or Hash of host, protocol, port, and path. This will be more robust and flexible.
# TODO: remove request_uri and route recognition hacks
#
#
module ActionController

  protected
  # Don't rewrite any urls unless BASE_URL has been set 
  def self.check_mode_and_base
    Object.const_defined? 'BASE_URL'
  end
  
  def self.reset_asset_host_and_route_optimization
    if check_mode_and_base
      # Set the asset host for CSS, JS, and image files if we're in production mode and the base_path has been configured.
      ActionController::Base.asset_host = BASE_URL
      # disable optimizations - we need all URLS to be run through routing for this to work.
      # QUESTION: tests pass on RoR 2.3.2 with optimized_named_routes enabled, but leaving this here for legacy
      ActionController::Base::optimise_named_routes = false
    end
  end
  
  reset_asset_host_and_route_optimization
  
  # Overriding the base UrlRewriter classes to get rewrite_url to always prepend the BASE_URL specified
  # in the config file
  class UrlRewriter
    # Prepends the BASE_URL to all of the URL requests created by the 
    # URL rewriter in Rails. This includes url_for, link_to, and route generation.
    # Route recognition is handled in recognize_path which is modified as well.
    # +:host+, +:port+, and +:protocol+ options will be ignored. 
    def rewrite_url_with_reverse_proxy_fix(options)
      return rewrite_url_without_reverse_proxy_fix(options) unless ActionController::check_mode_and_base 
      
      options = self.class.default_url_options.merge(options)
      base_url_with_authentication = BASE_URL.gsub("://", "://#{rewrite_authentication(options)}")
      
      url = rewrite_url_without_reverse_proxy_fix(options.except(:user, :password, :port, :host, :protocol))
      unless options[:skip_relative_url_root]
        url = url.gsub(@request.protocol + @request.host_with_port, '')
        url = base_url_with_authentication + url unless options[:only_path]
      end
      url
    end
    alias_method_chain :rewrite_url,  :reverse_proxy_fix
  end
  
  class Request
    # Request_uri usually returns the path relative to the root of the application. However, if you try to do
    # redirect_to(request_uri) then you may get unexpected results. This method overwrites request_uri to
    # always include the full front-facing path. This also breaks route recognition, so this is addressed in ActionController::Routing::RouteSet::recognize_path
    #
    # QUESTION: But why use redirect_to(request.request_uri) over redirect_to(request.url)?
    #
    def request_uri_with_reverse_proxy_fix
      uri = request_uri_without_reverse_proxy_fix
      return uri unless ActionController::check_mode_and_base 
      BASE_URL + uri unless uri.include?(BASE_URL)
    end
    alias_method_chain :request_uri,  :reverse_proxy_fix
    
    def path_with_reverse_proxy_fix
      path = path_without_reverse_proxy_fix
      return path unless ActionController::check_mode_and_base 
      path.gsub(BASE_URL, '')
    end
    alias_method_chain :path, :reverse_proxy_fix
    
    def url_with_reverse_proxy_fix
      ActionController::check_mode_and_base ? request_uri : url_without_reverse_proxy_fix
    end
    alias_method_chain :url, :reverse_proxy_fix
  end

  module Routing
    class RouteSet
      # Changes to request_uri to include the BASE_URL cause the route recognition to break.
      # This method simply removes the BASE_URL if it's found and then passes it on to the original
      # recognize_path method.
      def recognize_path_with_reverse_proxy_fix(path, environment={})
        return recognize_path_without_reverse_proxy_fix(path, environment) unless ActionController::check_mode_and_base
        
        path = CGI.unescape(path)
        path = path.gsub(BASE_URL, "") if ActionController::check_mode_and_base
        recognize_path_without_reverse_proxy_fix(path, environment)
      end
      alias_method_chain :recognize_path,  :reverse_proxy_fix
    end
  end
end