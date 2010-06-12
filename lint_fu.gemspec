# -*- encoding: utf-8 -*-

require 'rubygems'

spec = Gem::Specification.new do |s|
  s.required_rubygems_version = nil if s.respond_to? :required_rubygems_version=
  s.required_ruby_version = Gem::Requirement.new(">= 1.8.7")

  s.name    = 'lint_fu'
  s.version = '0.8'
  s.date    = '2010-06-11'

  s.authors = ['Tony Spataro']
  s.email   = 'code@tracker.xeger.net'
  s.homepage= 'http://github.com/xeger/lint_fu'
  
  s.summary = %q{Security scanner that performs static analysis of Rails code.}
  s.description = %q{This plugin for Rails can find (some!) security defects in your code.}

  s.add_runtime_dependency('ruby_parser', [">= 2.0.4"])
  s.add_runtime_dependency('ruby2ruby', [">= 1.2.4"])
  s.add_runtime_dependency('activesupport', [">= 2.1.2"])

  basedir = File.dirname(__FILE__)
  candidates = ['lint_fu.gemspec', 'init.rb', 'MIT-LICENSE', 'README.rdoc'] +
            Dir['lib/**/*'] +
            Dir['tasks/**/*']
  s.files = candidates.sort
end

if $PROGRAM_NAME == __FILE__
   Gem.manage_gems if Gem::RubyGemsVersion.to_f < 1.0
   Gem::Builder.new(spec).build
end
