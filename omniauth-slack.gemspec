# coding: utf-8
require File.expand_path('../lib/omniauth-slack/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name          = 'omniauth-slack'
  spec.version       = Omniauth::Slack::VERSION
  spec.authors       = ['kimura']
  spec.email         = ['kimura@enigmo.co.jp']
  spec.description   = 'OmniAuth strategy for Slack'
  spec.summary       = 'OmniAuth strategy for Slack'
  spec.homepage      = 'https://github.com/kmrshntr/omniauth-slack.git'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
                                        .reject { |f| f.match(%r{^(spec)/}) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'omniauth-oauth2', '~> 1.3.1'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'mocha'
  spec.add_development_dependency 'rubocop'
end
