desc "Calls the install script again to reconfigure the plugin's BASE_PATH."
task :proxy_config do
  system "ruby vendor/plugins/reverse_proxy_fix/install.rb"
end
