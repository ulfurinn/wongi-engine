# -*- encoding: utf-8 -*-
require File.expand_path('../lib/wongi-engine/version', __FILE__)

def git?
  File.exists?(".git")
end

def hg?
  File.exists?(".hg")
end

Gem::Specification.new do |gem|
  gem.authors       = ["Valeri Sokolov"]
  gem.email         = ["ulfurinn@ulfurinn.net"]
  gem.description   = %q{A rule engine.}
  gem.summary       = %q{A forward-chaining rule engine in pure Ruby.}
  gem.homepage      = "https://github.com/ulfurinn/wongi-engine"
  gem.licenses      = %w(MIT)

  if git?
    gem.files       = `git ls-files`.split($\)
  elsif hg?
    gem.files       = `hg st -cn`.split($\)
  else
    raise "cannot enumerate files: not a git or hg repository"
  end
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
