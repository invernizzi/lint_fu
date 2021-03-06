# -*- mode: ruby; encoding: utf-8 -*-

require 'rubygems'

spec = Gem::Specification.new do |s|
  s.required_rubygems_version = nil if s.respond_to? :required_rubygems_version=
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7")

  s.name    = 'lint_fu'
  s.version = '0.6.0'
  s.date    = '2011-06-14'

  s.authors = ['Tony Spataro']
  s.email   = 'code@tracker.xeger.net'
  s.homepage= 'http://github.com/xeger/lint_fu'
  
  s.summary = %q{Security scanner that performs static analysis of Ruby code.}
  s.description = %q{This tool helps identify bugs in your code. It is Rails-centric but its modular design allows support for other application frameworks.}

  s.add_runtime_dependency('trollop', [">= 1.16.0"])
  s.add_runtime_dependency('ruby_parser', ["~> 2.0"])
  s.add_runtime_dependency('ruby2ruby', ["~> 1.2"])
  s.add_runtime_dependency('activesupport', [">= 2.3"])
  s.add_runtime_dependency('i18n', [">= 0.6.0"])
  s.add_runtime_dependency('builder', ["~> 2.1"])
  s.add_runtime_dependency('RedCloth', ["~> 4.2"])

  s.add_development_dependency('rake', [">= 0.8.7"])
  s.add_development_dependency('ruby-debug', [">= 0.10.3"])
  s.add_development_dependency('rspec', ["~> 1.3"])
  s.add_development_dependency('flexmock', ["~> 0.8"])
  s.add_development_dependency('cucumber', ["~> 0.8"])
  s.add_development_dependency('rails', ["~> 3.0"])

  s.executables = ["lint_fu"]

  candidates = ['lint_fu.gemspec', 'MIT-LICENSE', 'README.rdoc'] +
               Dir['lib/**/*'] +
               Dir['bin/*']  
  s.files = candidates.sort
end
