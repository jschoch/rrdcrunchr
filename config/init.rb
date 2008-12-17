# Go to http://wiki.merbivore.com/pages/init-rb

#  use_orm :none
use_test :rspec
use_template_engine :erb

# Specify a specific version of a dependency
# dependency "RedCloth", "> 3.0"
dependency "merb-assets",  ">1.0"
dependency "merb-more",  ">1.0"
  require 'rubygems'
#  require 'hpricot'
  require 'erb' 
  require 'yaml'
  require 'gchart'

CONF = YAML.load_file("./rcr.yaml")
Merb::BootLoader.before_app_loads do
  # This will get executed after dependencies have been loaded but before your app's classes have loaded.
end
 
Merb::BootLoader.after_app_loads do
  # This will get executed after your app's classes have been loaded.
    require 'lib/rrdcrunchr.rb'
end

# Move this to application.rb if you want it to be reloadable in dev mode.
Merb::Router.prepare do
  match('/').to(:controller => "rrdcrunchr", :action =>'index')
  match('/foo').to(:controller => "rrdcrunchr", :action =>'foo')
  default_routes
end

Merb::Config.use { |c|
  c[:environment]         = 'production',
  c[:framework]           = {},
  c[:log_level]           = :debug,
  c[:log_stream]          = STDOUT,
  # or use file for logging:
  # c[:log_file]          = Merb.root / "log" / "merb.log",
  c[:use_mutex]           = false,
  c[:session_store]       = 'cookie',
  c[:session_id_key]      = '_rrdcrunchr_session_id',
  c[:session_secret_key]  = 'ff7bd582e6f458507313c2392d6e1dae1f9dc184',
  c[:exception_details]   = true,
  c[:reload_classes]      = true,
  c[:reload_templates]    = true,
  c[:reload_time]         = 0.5
  c[:reload_files] = true
}
