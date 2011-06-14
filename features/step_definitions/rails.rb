require 'tempfile'

Given /^a Rails app$/ do
  @original_pwd = Dir.pwd
  @rails_root = Dir.mktmpdir('lint_fu')

  runshell("rails new #{@rails_root} -q")
  Dir.chdir(@rails_root)

  runshell('git init')
  runshell('git add .')
  runshell('git commit -q -m "Initial commit"')
end

Given /^a ([A-Z][\w:]+) model$/ do |klass_name|
  base_klass = 'ActiveRecord::Base'
  path = File.join(@rails_root, 'app', 'models', klass_name.underscore + '.rb')
  file = File.open(path, 'w')
  file.write <<EOS
class #{klass_name} < #{base_klass}
end
EOS
  file.close
end

Given /^a ([A-Z][\w:]+) model defined by$/ do |klass_name, body|
  base_klass = 'ActiveRecord::Base'
  body = body.split("\n").map { |l| '  ' + l}
  path = File.join(@rails_root, 'app', 'models', klass_name.underscore + '.rb')
  file = File.open(path, 'w')
  file.write <<EOS
class #{klass_name} < #{base_klass}
#{body.join("\n")}
end
EOS
  file.close
end

Given /^a ([A-Z][\w:]+) controller defined by$/ do |klass_name, body|
  klass_name = "#{klass_name.pluralize.camelize}Controller"

  body = body.split("\n")
  #wrap code in a method definition if user didn't provide one
  unless (body.first =~ /\s*def /) && (body.last =~ /\s*end/)
    body = body.map { |l| '  ' + l}
    body.unshift('def index')
    body.push('end')
  end
  #indentation for pretty printing (oooh!)
  body = body.map { |l| '  ' + l}

  path = File.join(@rails_root, 'app', 'controllers', klass_name.underscore + '.rb')
  file = File.open(path, 'w')
  file.write <<EOS
class #{klass_name} < ApplicationController
#{body.join("\n")}
end
EOS
  file.close
end

Given /^a simple Rails app$/ do
  Given 'a Rails app'
  Given 'a Company model defined by', <<-EOS
    belongs_to :owner, :class_name=>'User'
  EOS
  Given 'a User model defined by', <<-EOS
    belongs_to :company
    named_scope :verified, :conditions=>'verified_at IS NOT NULL'
  EOS
end

After do
  Dir.chdir(@original_pwd) if @original_pwd
  if @rails_root && File.directory?(@rails_root)
    FileUtils.rm_rf(@rails_root)
  end
end
