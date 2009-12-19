require File.expand_path(File.join(File.dirname(__FILE__), '..', 'init.rb'))

namespace :lint do
  desc "Scan the application for common security defects"
  task "security" do
    builder   = LintFu::Rails::ApplicationModelBuilder.new(RAILS_ROOT)
    context   = builder.application

    scan            = LintFu::Scan.new(RAILS_ROOT)
    scm             = LintFu::SourceControlProvider.for_directory(RAILS_ROOT)

    raise LintFu::ProviderError.new("Unable to identify the source control provider for #{RAILS_ROOT}") unless scm

    controllers_dir = File.join(RAILS_ROOT, 'app', 'controllers')
    Dir.glob(File.join(controllers_dir, '**', '*.rb')).each do |f|
      contents = File.read(f)
      sexp = RubyParser.new.parse(contents)
      LintFu::Rails::ControllerVisitor.new(scan, context, f).process(sexp)      
    end

    scan.issues.each do |issue|
      puts '=' * 40
      puts issue.brief
      puts word_wrap(issue.detail)
      puts '-' * 20
      puts scm.excerpt(file=issue.file, line=issue.line)
      puts '=' * 40
    end
  end

  private
  def word_wrap(str, len=60)
    str.gsub(/\t/,"     ").gsub(/.{1,78}(?:\s|\Z)/){($& + 5.chr).gsub(/\n\005/,"\n").gsub(/\005/,"\n")}
  end
end
