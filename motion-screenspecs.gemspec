# -*- encoding: utf-8 -*-
VERSION = "0.0.1"

Gem::Specification.new do |spec|
  spec.name          = "motion-screenspecs"
  spec.version       = VERSION
  spec.authors       = ["Clay Allsopp"]
  spec.email         = ["clay.allsopp@gmail.com"]
  spec.description   = "Test your RubyMotion app regressions using screenshot comparison."
  spec.summary       = "Test your RubyMotion app regressions using screenshot comparison."
  spec.homepage      = "https://github.com/usepropeller/motion-screenspecs"
  spec.license       = "MIT"

  files = []
  files << 'README.md'
  files.concat(Dir.glob('lib/**/*.rb'))
  spec.files         = files
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'motion-screenshots', '~> 0.0.5'
  spec.add_dependency 'chunky_png', '~> 1.2.0'
  spec.add_dependency 'motion-env', '~> 0.0.1'
  spec.add_development_dependency "rake"
end
