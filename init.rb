#Required Ruby library elements
require 'set'
require 'digest/sha1'

skip_lint_fu = false

#Required gems
begin
  require 'ruby_parser'
  require 'sexp_processor'
  require 'ruby2ruby'
  require 'builder'
  require 'redcloth'
rescue LoadError => e
  puts "lint_fu is unavailable; " + e.message
  skip_lint_fu = true
end

#########################################################################################
# I don't like to rely on Rails' auto-load magic in plugin code; that stuff is best
# reserved for the app business logic. Instead, we'll explicitly require each lint_fu
# source file in an order that preserves the ordering of dependencies between files.
#########################################################################################

unless skip_lint_fu
  basedir = File.dirname(__FILE__)
  libdir = File.expand_path(File.join(basedir, 'lib'))

  requires = []

  #######################################
  # lib
  curdir    = libdir
  requires << File.join(curdir, 'lint_fu.rb')

  #######################################
  # lib/lint_fu
  curdir    = File.join(libdir, 'lint_fu')
  requires << File.join(curdir, 'model_element.rb')
  requires << File.join(curdir, 'model_element_builder.rb')
  requires << File.join(curdir, 'source_control_provider.rb')
  requires << File.join(curdir, 'issue.rb')
  requires << File.join(curdir, 'checker.rb')
  requires << File.join(curdir, 'visitor.rb')
  requires << File.join(curdir, 'scan.rb')
  requires << File.join(curdir, 'report.rb')

  #######################################
  # lib/lint_fu/active_record
  curdir    = File.join(libdir, 'lint_fu', 'active_record')
  requires << File.join(curdir, 'model_model.rb')
  requires << File.join(curdir, 'model_model_builder.rb')

  #######################################
  # lib/lint_fu/rails
  curdir    = File.join(libdir, 'lint_fu', 'rails')
  requires << File.join(curdir, 'application_model.rb')
  requires << File.join(curdir, 'application_model_builder.rb')
  requires << File.join(curdir, 'buggy_eager_load_checker.rb')
  requires << File.join(curdir, 'sql_injection_checker.rb')
  requires << File.join(curdir, 'unsafe_find_checker.rb')

  #######################################
  # lib/lint_fu/action_pack
  curdir    = File.join(libdir, 'lint_fu', 'action_pack')
  requires << File.join(curdir, 'model_controller.rb')
  requires << File.join(curdir, 'model_controller_builder.rb')

  #######################################
  # lib/lint_fu/source_control
  curdir    = File.join(libdir, 'lint_fu', 'source_control')
  requires << File.join(curdir, 'git.rb')

  requires.each do |f|
    require File.expand_path(f)
  end
end