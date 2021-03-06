# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chess/version'

Gem::Specification.new do |spec|
  spec.name          = "chess-rb"
  spec.version       = Chess::VERSION
  spec.authors       = ["K-2052"]
  spec.email         = ["k@2052.me"]
  spec.summary       = %q{TODO: Write a short summary. Required.}
  spec.description   = %q{TODO: Write a longer description. Optional.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency             'hamster'
  spec.add_development_dependency 'bundler',             '~> 1.7'
  spec.add_development_dependency 'rake',                '10.4.2'
  spec.add_development_dependency 'rspec',               '3.1.0'
  spec.add_development_dependency 'rubocop',             '0.28.0'
  spec.add_development_dependency 'coveralls',           '~> 0.7'
end
