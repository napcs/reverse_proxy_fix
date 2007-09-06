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
	
	# Set the asset host for CSS, JS, and image files if we're in production mode and the base_path has been configured.
	if check_mode_and_base
		ActionController::Base.asset_host = BASE_URL
	end
	
	class UrlRewriter
	
		alias old_rewrite_url rewrite_url
		
		# Prepends the BASE_URL to all of the URL requests created by the 
		# URL rewriter in Rails.
		def rewrite_url(path, options)
			url = old_rewrite_url(path, options)
			if ActionController::check_mode_and_base
			  unless options[:skip_relative_url_root]
					
			    url = url.gsub(@request.protocol + @request.host_with_port, '')
			    url = BASE_URL + url
			  end
			end
			url
		
		end
	end

end