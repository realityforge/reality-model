# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name               = %q{reality-model}
  s.version            = '1.4.0'
  s.platform           = Gem::Platform::RUBY

  s.authors            = ['Peter Donald']
  s.email              = %q{peter@realityforge.org}

  s.homepage           = %q{https://github.com/realityforge/reality-model}
  s.summary            = %q{Utility classes for defining a domain model.}
  s.description        = %q{Utility classes for defining a domain model.}

  s.files              = `git ls-files`.split("\n")
  s.test_files         = `git ls-files -- {spec}/*`.split("\n")
  s.executables        = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths      = %w(lib)

  s.rdoc_options       = %w(--line-numbers --inline-source --title reality-model)

  s.add_dependency 'reality-core', '>= 1.8.0'
  s.add_dependency 'reality-naming', '>= 1.9.0'

  s.add_development_dependency 'reality-facets', '>= 1.12.0'
  s.add_development_dependency(%q<minitest>, ['= 5.9.1'])
  s.add_development_dependency(%q<test-unit>, ['= 3.1.5'])
end
