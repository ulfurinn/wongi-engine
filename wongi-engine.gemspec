# -*- encoding: utf-8 -*-
require File.expand_path('../lib/wongi-engine/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Valeri Sokolov"]
  gem.email         = ["ulfurinn@ulfurinn.net"]
  gem.description   = %q{A rule engine.}
  gem.summary       = %q{A rule engine.}
  gem.homepage      = "https://github.com/ulfurinn/wongi-engine"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "wongi-engine"
  gem.require_paths = ["lib"]
  gem.version       = Wongi::Engine::VERSION

  gem.add_development_dependency 'rspec', '~> 2.14.1', '< 3.0.0'
end
