require File.expand_path(File.join(File.dirname(__FILE__), '..', 'init.rb'))

namespace :lint do
  desc "Scan the application for common security defects"
  task "security" do
    scan    = LintFu::Scan.new(RAILS_ROOT)
    scm     = LintFu::SourceControlProvider.for_directory(RAILS_ROOT)

    #Build a model of the application we are scanning.
    builder = LintFu::Rails::ApplicationModelBuilder.new(RAILS_ROOT)
    context = builder.application
    raise LintFu::ProviderError.new("Unable to identify the source control provider for #{RAILS_ROOT}") unless scm

    #Using the model we built, scan the controllers for security bugs.
    controllers_dir = File.join(RAILS_ROOT, 'app', 'controllers')
    Dir.glob(File.join(controllers_dir, '**', '*.rb')).each do |f|
      contents = File.read(f)
      sexp = RubyParser.new.parse(contents)
      LintFu::Rails::ControllerVisitor.new(scan, context, f).process(sexp)      
    end

    authors = Hash.new
    scan.issues.each do |issue|
      commit, author = scm.blame(issue.relative_file, issue.line)
      authors[author] ||= Set.new
      authors[author] << issue
    end

    #Sort in decreasing order of number of bugs contributed
    sorted_authors = authors.keys.sort { |x,y| authors[y].size <=> authors[x].size }

    x = Builder::XmlMarkup.new(:target => $stdout, :indent => 2)
    x.html do |html|
      html.head do |head|
        head.title 'Rails Security Scan'
      end
      html.body do |body|
        body.h1 'Rails Security Scan'

        body.h2 'Summary'
        body.p "#{scan.issues.size} issues found."

        body.h3 'Contributors'
        body.table do |table|
          sorted_authors.each do |author|
            table.tr do |tr|
              tr.td(author)
              tr.td(authors[author].size.to_s)
              tr.td do |td|
                authors[author].each do |issue|
                  td.a(issue.hash[0..4], :href=>"#issue_#{issue.hash}")
                end
              end
            end
          end
        end

        body.h2 'Detailed Results'
        scan.issues.each do |issue|
          body.div(:class=>'issue', :id=>"issue_#{issue.hash}") do |div|
            div.h4 issue.brief
            div.span(issue.detail, :class=>'detail')
            div.pre(scm.excerpt(issue.file, issue.line, :blame=>false), :name=>'code', :class=>'ruby')
          end
        end
        
      end
    end
  end

  private
  def word_wrap(str, len=60)
    str.gsub(/\t/,"     ").gsub(/.{1,78}(?:\s|\Z)/){($& + 5.chr).gsub(/\n\005/,"\n").gsub(/\005/,"\n")}
  end
end
