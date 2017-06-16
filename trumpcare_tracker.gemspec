# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'trumpcare_tracker/version'

Gem::Specification.new do |spec|
  spec.name          = 'trumpcare_tracker'
  spec.version       = TrumpcareTracker::VERSION
  spec.authors       = ['M. Simon Borg']
  spec.email         = ['msimonborg@gmail.com']

  spec.summary       = 'Track the Twitter mentions of Trumpcare by '\
    'Democratic US Senators'
  spec.description   = 'Track the Twitter mentions of Trumpcare by '\
    'Democratic US Senators'
  spec.homepage      = 'https://github.com/msimonborg/trumpcare-tracker'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'twitter', '~> 6.1.0'
  spec.add_dependency 'pyr', '~> 0.4.0'
  spec.add_dependency 'nokogiri', '~> 1.8.0'

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
end
