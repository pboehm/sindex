# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sindex/version'

Gem::Specification.new do |gem|
  gem.name          = "sindex"
  gem.version       = Sindex::VERSION
  gem.authors       = ["Philipp Böhm"]
  gem.email         = ["philipp-boehm@live.de"]
  gem.description   = %q{Tool and library that manages the episodes you have seen in different tv series}
  gem.summary       = %q{Series-Index that manages your watched episodes}
  gem.homepage      = "https://github.com/pboehm/sindex"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency(%q<nokogiri>, [">= 1.5"])
  gem.add_runtime_dependency(%q<hashconfig>, [">= 0.0.1"])
end
