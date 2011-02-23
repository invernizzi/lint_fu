require 'rubygems'
require 'rake'
require 'spec/rake/spectask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/clean'

desc "Run unit tests"
task :default => :gem

desc 'Generate documentation for the lint_fu plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'lint-fu'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

gemtask = Rake::GemPackageTask.new(Gem::Specification.load("lint_fu.gemspec")) do |package|
  package.package_dir = ENV['PACKAGE_DIR'] || 'pkg'
  package.need_zip = true
  package.need_tar = true
end

directory gemtask.package_dir

CLEAN.include(gemtask.package_dir)
