# Install script for Reverse Proxy Fix
# Prompts users for the desired source base path
# and writes the path to the configuration file used
# by the plugin.
puts "########################################################"
puts "# reverse_proxy_fix plugin                             #"
puts "# Set up the base url of your proxy server             #"
puts "########################################################"
puts ""
puts "Enter the base url you wish to use without the trailing slash (example: http://external.mycompany.com/myapp)"
base_url = STDIN.gets

base_url.chop!

d = Dir.getwd

if !d.include?('/vendor/plugins/reverse_proxy_fix')
  d += '/vendor/plugins/reverse_proxy_fix'
elsif !d.include?('/vendor/plugins/')
  
end
config_file = d + "/lib/config.rb"

begin
  File.open(config_file, "w") do |t|
  	t << "BASE_URL=\"#{base_url}\""
  end	
  puts "The file #{config_file} has been modified. The plugin will be activated when you run your application in production mode."
rescue
  puts "I couldn't find your config file. I'm looking for a file called 'config.rb' and it should reside in the /lib file of the plugin. Since I can't find it, you may want to just open it yourself and change the value for BASE_PATH. Be sure that line is uncommented!!!!!!"
end
