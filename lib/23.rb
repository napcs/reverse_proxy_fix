# Reverse proxy fix for Rails 2.3
# Fixes for the renamig of abstract_request to request
module ActionController
		
	protected
	# Configure the prefix on the url only if we're running in production mode
	# Throws an exception if the BASE_URL constant has not been configured in
	# config.rb
	def self.check_mode_and_base
 
		if RAILS_ENV == 'production'
			begin
				BASE_URL
			rescue
				raise "You need to configure your base url. See the reverse_proxy_fix/lib/config.rb file to set this value!"
			end
		else
			return false
		end
	end
	
	if check_mode_and_base
	  # Set the asset host for CSS, JS, and image files if we're in production mode and the base_path has been configured.
		ActionController::Base.asset_host = BASE_URL
	  # disable optimizations - we need all URLS to be run through routing for this to work.
		ActionController::Base::optimise_named_routes = false
	end
	
	
	# Overriding the base UrlRewriter classes to get rewrite_url to always prepend the BASE_URL specified
	# in the config file
	class UrlRewriter
	
		alias old_rewrite_url rewrite_url
		
		# Prepends the BASE_URL to all of the URL requests created by the 
		# URL rewriter in Rails. This includes url_for, link_to, and route generation.
		# Route recognition is handled in recognize_path which is modified as well.
		def rewrite_url(options)

			url = old_rewrite_url(options)
			if ActionController::check_mode_and_base
			  unless options[:skip_relative_url_root]
					
			    url = url.gsub(@request.protocol + @request.host_with_port, '')
			    url = BASE_URL + url
			  end
			end
			url
		
		end
	end
	
	
	# Need to modify the request slightly
	class Request
		alias old_request_uri request_uri
		
		# Request_uri usually returns the path relative to the root of the application. However, if you try to do
		# redirect_to(request_uri) then you may get unexpected results. This method overwrites request_uri to
		# always include the full front-facing path. This also breaks route recognition, so this is addressed in ActionController::Routing::RouteSet::recognize_path
		def request_uri
		  uri = old_request_uri
                  if ActionController::check_mode_and_base
                    uri = BASE_URL + uri unless uri.include?(BASE_URL)
                  end
                  uri
	    end
    end

	module Routing
		class RouteSet
			alias old_recognize_path recognize_path
		
		    # Changes to request_uri to include the BASE_URL cause the route recognition to break.
			# This method simply removes the BASE_URL if it's found and then passes it on to the original
			# recognize_path method.
			def recognize_path(path, environment={})
		        
                        path = CGI.unescape(path)
                        
		        path = path.gsub(BASE_URL, "") if ActionController::check_mode_and_base
                        
				old_recognize_path(path, environment)
			end
		      
		end
    end



end