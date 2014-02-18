# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nebula/version'

Gem::Specification.new do |spec|
  spec.name          = "nebula"
  spec.version       = Nebula::VERSION
  spec.authors       = ["Peter Brindisi"]
  spec.email         = ["peter.brindisi@gmail.com"]
  spec.summary       = %q{Organize unstructured data in a graph}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ["lib"]

  spec.add_dependency "pg"
  spec.add_dependency "yajl-ruby"
  spec.add_dependency "hashie"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
