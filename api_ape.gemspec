$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "api_ape/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "api_ape"
  s.version     = ApiApe::VERSION
  s.authors     = ["kjjgibson"]
  s.email       = ["kennethjjgibson@gmail.com"]
  s.homepage    = ""
  s.summary     = "Summary of ApiApe."
  s.description = "Description of ApiApe."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 4.2.7.1"

  s.add_development_dependency "pg"
  s.add_development_dependency "rspec-rails"
end
