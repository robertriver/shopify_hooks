$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "shopify_hooks/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "shopify_hooks"
  s.version     = ShopifyHooks::VERSION
  s.authors     = ["Garrett Boone"]
  s.email       = ["Boone.Garrett@gmail.com"]
  s.homepage    = "https://www.github.com"
  s.summary     = "sets up basic api routes and workers for shopify"
  s.description = "sets up basic api routes and workers for shopify"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.3"
  s.add_dependency "shopify_api"
  s.add_dependency "jsonpath"
  # s.add_dependency "delayed_job_active_record"

  s.add_development_dependency "pg"
end
