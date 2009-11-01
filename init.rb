#Required Ruby library elements
require 'set'

#Required gems
require 'ruby_parser'
require 'sexp_processor'

basedir = File.dirname(__FILE__)
libdir = File.join(basedir, 'lib')

Dir.glob(File.join(libdir, '**', '*.rb')). each do |f|
  require f
end