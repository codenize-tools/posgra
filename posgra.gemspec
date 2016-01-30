# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'posgra/version'

Gem::Specification.new do |spec|
  spec.name          = 'posgra'
  spec.version       = Posgra::VERSION
  spec.authors       = ['Genki Sugawara']
  spec.email         = ['sugawara@cookpad.com']

  spec.summary       = %q{Posgra is a tool to manage PostgreSQL roles/permissions.}
  spec.description   = %q{Posgra is a tool to manage PostgreSQL roles/permissions.}
  spec.homepage      = 'https://github.com/winebarrel/posgra'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'pg'
  spec.add_dependency 'term-ansicolor'
  spec.add_dependency 'hashie'
  spec.add_dependency 'thor'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'unindent'
end
