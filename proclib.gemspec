# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'proclib/version'

Gem::Specification.new do |spec|
  spec.name          = "proclib"
  spec.version       = Proclib::VERSION
  spec.authors       = ["Jack Forrest"]
  spec.email         = ["jack@jrforrest.net"]

  spec.summary       = %q{Provides tools for subprocess management}
  spec.description   = "Proclib allows easy management of subprocess with a "\
    "very high-level interface, with niceties such as multiplexed logging of "\
    "output to logfiles and the console, output capture, and signal propagation."
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"
end
