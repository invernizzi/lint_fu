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

    puts "<html>"
    puts "<body>"
    puts "<h1>Rails Security Scan</h1>"
    puts "<h2>Summary</h2>"
    puts "<p>#{scan.issues.size} issues found.</p>"

    puts %Q{<h2>Detailed Results</h2>}
    scan.issues.each do |issue|
      puts %Q{<div class="issue" id="issue_#{issue.hash}">}
      puts %Q{<h4>#{issue.brief}</h4>}
      puts %Q{<span class="detail">#{issue.detail}</span>}
      puts %Q{<code class="issue_excerpt lang_ruby">}
      puts scm.excerpt(file=issue.file, line=issue.line, :blame=>false)
      puts "</code>"
      puts "</div>"
    end
    puts "</body>"
    puts "</html>"
  end

  private
  def word_wrap(str, len=60)
    str.gsub(/\t/,"     ").gsub(/.{1,78}(?:\s|\Z)/){($& + 5.chr).gsub(/\n\005/,"\n").gsub(/\005/,"\n")}
  end
end
