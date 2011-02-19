# -*- encoding: utf-8 -*-

require 'rubygems'

spec = Gem::Specification.new do |s|
  s.required_rubygems_version = nil if s.respond_to? :required_rubygems_version=
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7")

  s.name    = 'lint_fu'
  s.version = '0.5.0'
  s.date    = '2011-02-19'

  s.authors = ['Tony Spataro']
  s.email   = 'code@tracker.xeger.net'
  s.homepage= 'http://github.com/xeger/lint_fu'
  
  s.summary = %q{Security scanner that performs static analysis of Ruby code.}
  s.description = %q{This tool helps identify bugs in your code. It is Rails-centric but its modular design allows support for other application frameworks.}

  s.add_runtime_dependency('ruby_parser', ["~> 2.0"])
  s.add_runtime_dependency('ruby2ruby', ["~> 1.2"])
  s.add_runtime_dependency('activesupport', ["~> 2.3"])

  s.executables = ["lint_fu"]

  candidates = ['lint_fu.gemspec', 'MIT-LICENSE', 'README.rdoc'] +
               Dir['lib/**/*'] +
               Dir['bin/*']  
  s.files = candidates.sort
end

if $PROGRAM_NAME == __FILE__
   Gem.manage_gems if Gem::RubyGemsVersion.to_f < 1.0
   Gem::Builder.new(spec).build
end
