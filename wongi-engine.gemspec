# -*- encoding: utf-8 -*-
require File.expand_path('../lib/wongi-engine/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Valeri Sokolov"]
  gem.email         = ["ulfurinn@ulfurinn.net"]
  gem.description   = %q{A rule engine.}
  gem.summary       = %q{A forward-chaining rule engine in pure Ruby.}
  gem.homepage      = "https://github.com/ulfurinn/wongi-engine"
  gem.licenses      = %w(MIT)

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "wongi-engine"
  gem.require_paths = ["lib"]
  gem.version       = Wongi::Engine::VERSION

  gem.add_development_dependency 'rake', '~> 10'
  gem.add_development_dependency 'pry', '~> 0.10'
  gem.add_development_dependency 'rspec', '~> 3.1', '< 3.2'
  gem.add_development_dependency 'rspec-collection_matchers', '~> 1.1'
end
