require 'English'
require File.expand_path('lib/wongi-engine/version', __dir__)

module GemHelper
  def self.git?
    File.exist?('.git')
  end

  def self.hg?
    File.exist?('.hg')
  end
end

Gem::Specification.new do |gem|
  gem.authors       = ['Valeri Sokolov']
  gem.email         = ['ulfurinn@ulfurinn.net']
  gem.description   = 'A rule engine.'
  gem.summary       = 'A forward-chaining rule engine in pure Ruby.'
  gem.homepage      = 'https://github.com/ulfurinn/wongi-engine'
  gem.licenses      = %w[MIT]

  gem.files = if GemHelper.git?
                `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
              elsif GemHelper.hg?
                `hg st -cn`.split($OUTPUT_RECORD_SEPARATOR)
              else
                raise 'cannot enumerate files: not a git or hg repository'
              end
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.name          = 'wongi-engine'
  gem.require_paths = ['lib']
  gem.version       = Wongi::Engine::VERSION

  gem.add_development_dependency 'pry', '~> 0.10'
  gem.add_development_dependency 'rake', '~> 12.3'
  # gem.add_development_dependency 'pry-byebug', '~> 2.0'
  gem.add_development_dependency 'rspec', '~> 3.1'
  gem.add_development_dependency 'rspec-collection_matchers', '~> 1.1'
  gem.metadata['rubygems_mfa_required'] = 'true'
end
