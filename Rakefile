require 'rubygems'
require 'rake'
require 'spec/rake/spectask'
require 'rake/rdoctask'

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

desc "Build lint_fu gem"
task :gem do
   ruby 'lint_fu.gemspec'
   pkg_dir = File.join(File.dirname(__FILE__), 'pkg')
   FileUtils.mkdir_p(pkg_dir)
   FileUtils.mv(Dir.glob(File.join(File.dirname(__FILE__), '*.gem')), pkg_dir)
end
