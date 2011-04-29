require 'rubygems'
require 'bundler/setup'

basedir = File.expand_path('../..', __FILE__)
require File.join(basedir, 'lib', 'lint_fu')

def file_fixture(filename)
  fixture_dir = File.expand_path('../fixtures', __FILE__)
  filename = [filename] unless filename.is_a?(Array)
  path = [fixture_dir] + filename
  return File.readlines(File.join(*path))
end
