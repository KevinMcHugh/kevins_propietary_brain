# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kevins_propietary_brain/version'

Gem::Specification.new do |spec|
  spec.name          = "kevins_propietary_brain"
  spec.version       = KevinsPropietaryBrain::VERSION
  spec.authors       = ["Kevin McHugh"]
  spec.email         = ["kev@kevinmchugh.me"]
  spec.summary       = %q{ my very private, supa secret brain}
  spec.description   = %q{ I will not reveal my very secret algorithim}
  spec.homepage      = "https://github.com/KevinMcHugh/kevins_propietary_brain"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
