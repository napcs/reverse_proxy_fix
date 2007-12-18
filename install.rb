# Install script for Reverse Proxy Fix
# Prompts users for the desired source base path
# and writes the path to the configuration file used
# by the plugin.
require 'FileUtils'
puts "########################################################"
puts "# reverse_proxy_fix plugin                             #"
puts "# Configureation                                       #"
puts "########################################################"
puts ""
puts "Enter the base url you wish to use without the trailing slash (example: http://external.mycompany.com/myapp)"
base_url = STDIN.gets

base_url.chop!

puts "Please select your Rails version from the list of supported versions:"
puts " 1 : Rails 1.1.6"
puts " 2 : Rails 1.2.X"
puts " 3 : Rails 2.0"
version = STDIN.gets.chop!.to_i

d = Dir.getwd


if File.exists?("app")
   d += "/vendor/plugins/reverse_proxy_fix"
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


if version == 1
   version = "116"
elsif version == 2
   version = "123"
elsif version == 3
   version = "20"
else
   version = "123"
end


config_file = d + "/lib/#{version}.rb"

begin
  FileUtils.cp "#{d}/lib/#{version}.rb", "#{d}/lib/reverse_proxy_fix.rb"
  puts "Plugin successfully installed and configured"
rescue
    puts "I couldn't copy your file.  Remane #{d}/lib/#{version}.rb to #{d}/lib/reverse_proxy_fix.rb"
end




