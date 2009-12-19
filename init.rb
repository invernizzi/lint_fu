#Required Ruby library elements
require 'set'

#Required gems
require 'ruby_parser'
require 'sexp_processor'

basedir = File.dirname(__FILE__)
libdir = File.join(basedir, 'lib')

requires = [] 
requires += Dir.glob(File.join(libdir, '*.rb'))
requires += Dir.glob(File.join(libdir, 'lint_fu', '*.rb'))
requires += Dir.glob(File.join(libdir, 'lint_fu', 'active_record', '*.rb'))
requires += Dir.glob(File.join(libdir, 'lint_fu', 'rails', '*.rb'))
requires += Dir.glob(File.join(libdir, 'lint_fu', 'source_control', '*.rb'))

requires.each do |f|
  require File.expand_path(f)
end