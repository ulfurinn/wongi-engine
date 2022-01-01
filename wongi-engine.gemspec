# -*- encoding: utf-8 -*-
require File.expand_path('../lib/wongi-engine/version', __FILE__)

module GemHelper
  def self.git?
    File.exists?(".git")
  end

  def self.hg?
    File.exists?(".hg")
  end
end

Gem::Specification.new do |gem|
  gem.authors       = ["Valeri Sokolov"]
  gem.email         = ["ulfurinn@ulfurinn.net"]
  gem.description   = %q{A rule engine.}
  gem.summary       = %q{A forward-chaining rule engine in pure Ruby.}
  gem.homepage      = "https://github.com/ulfurinn/wongi-engine"
  gem.licenses      = %w(MIT)

  if GemHelper.git?
    gem.files       = `git ls-files`.split($\)
  elsif GemHelper.hg?
    gem.files       = `hg st -cn`.split($\)
  else
    raise "cannot enumerate files: not a git or hg repository"
  end
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "wongi-engine"
  gem.require_paths = ["lib"]
  gem.version       = Wongi::Engine::VERSION

  gem.add_development_dependency "rake", ">= 12.3.3"
  gem.add_development_dependency 'pry', '~> 0.10'
  # gem.add_development_dependency 'pry-byebug', '~> 2.0'
  gem.add_development_dependency 'rspec', '~> 3.1'
  gem.add_development_dependency 'rspec-collection_matchers', '~> 1.1'
end
