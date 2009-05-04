# Install script for Reverse Proxy Fix
# Prompts users for the desired source base path
# and writes the path to the configuration file used
# by the plugin.
require 'fileutils'
puts "########################################################"
puts "# reverse_proxy_fix plugin - v1.1                      #"
puts "# Configureation                                       #"
puts "########################################################"
puts ""
puts "Please select your Rails version from the list of supported versions:"
puts " 1 : Rails 1.1.6"
puts " 2 : Rails 1.2.X"
puts " 3 : Rails 2.0, 2.1, 2.2"
puts " 4 : Rails 2.3.x"
version = STDIN.gets.chop!.to_i

d = Dir.getwd

version_file = case version
  when 1
    "116"
  when 2
    "123"
  when 3
    "20"
  when 4
    "23"
  else 
    "123"
end

if version < 4
  puts "Enter the base url you wish to use without the trailing slash (example: http://external.mycompany.com/myapp)"
  base_url = STDIN.gets
  
  base_url.chop!
  
  
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
else
  puts "Add BASE_URL to any environment conf to enable reverse_proxy_fix"
end

config_file = d + "/lib/#{version_file}.rb"

begin
  FileUtils.cp "#{d}/lib/#{version_file}.rb", "#{d}/lib/reverse_proxy_fix.rb"
  puts "Plugin successfully installed and configured"
rescue
    puts "I couldn't copy your file.  Remane #{d}/lib/#{version_file}.rb to #{d}/lib/reverse_proxy_fix.rb"
end




