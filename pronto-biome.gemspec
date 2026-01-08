# frozen_string_literal: true

require_relative 'lib/pronto/biome/version'

Gem::Specification.new do |spec|
  spec.name          = 'pronto-biome'
  spec.version       = Pronto::BiomeVersion::VERSION
  spec.authors       = ['Sbastien']
  spec.email         = ['sbastien@users.noreply.github.com']

  spec.summary       = 'Pronto runner for Biome linter'
  spec.description   = 'Pronto runner for Biome, reports only on lines changed in the diff'
  spec.homepage      = 'https://github.com/Sbastien/pronto-biome'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.files = Dir['lib/**/*', 'LICENSE', 'README.md', 'CHANGELOG.md']
  spec.require_paths = ['lib']

  spec.add_dependency 'pronto', '~> 0.11.0'

  # Required for Ruby 3.4+ (removed from default gems)
  spec.add_development_dependency 'base64'
  spec.add_development_dependency 'faraday-retry'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.0'
  spec.add_development_dependency 'rubocop-rake', '~> 0.6'
  spec.add_development_dependency 'rubocop-rspec', '~> 3.0'

  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/Sbastien/pronto-biome/issues',
    'changelog_uri' => 'https://github.com/Sbastien/pronto-biome/blob/main/CHANGELOG.md',
    'homepage_uri' => spec.homepage,
    'source_code_uri' => 'https://github.com/Sbastien/pronto-biome',
    'rubygems_mfa_required' => 'true'
  }
end
