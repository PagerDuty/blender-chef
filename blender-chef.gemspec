# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'blender-chef'
  spec.version       = '0.0.1'
  spec.authors       = ['Ranjib Dey']
  spec.email         = ['ranjib@pagerduty.com']
  spec.summary       = %q{Chef search based host discovery for blender}
  spec.description   = %q{Discover hosts using chef search for blender}
  spec.homepage      = 'http://github.com/PagerDuty/blender-chef'
  spec.license       = 'Apache 2'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ['lib']

  spec.add_dependency 'pd-blender'
  spec.add_dependency 'chef'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'yard'
end
