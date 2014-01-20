# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'zit/version'

Gem::Specification.new do |spec|
  spec.name          = "zit"
  spec.version       = Zit::VERSION
  spec.authors       = ["Adam Panzer"]
  spec.email         = ["apanzerj@gmail.com"]
  spec.description   = %q{A tool to unify zendesk and git as well as jira and git.}
  spec.summary       = %q{Unify zendesk and git, jira and git.}
  spec.homepage      = "https://github.com/apanzerj/zit"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = ['zit']
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_runtime_dependency "git"
  spec.add_runtime_dependency "httparty"
  spec.post_install_message = "Remember to set ENV variables: jira_user, jira_pass, zendesk_user, zendesk_token."
end
