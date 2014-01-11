# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'zit/version'

Gem::Specification.new do |spec|
  spec.name          = "zit"
  spec.version       = Zit::VERSION
  spec.authors       = ["Adam Panzer"]
  spec.email         = ["apanzerj@gmail.com"]
  spec.description   = %q{A tool to unify zendesk and git}
  spec.summary       = %q{Unify zendesk and git}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = ['zit']
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
