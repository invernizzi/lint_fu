require File.expand_path(File.join(File.dirname(__FILE__), '..', 'init.rb'))

require 'composite_sexp_processor'

namespace :lint do
  STYLESHEET = <<-EOF
    table { border: 2px solid black }
    th    { color: white; background: black }
    td    { border-right: 1px dotted black; border-bottom: 1px dotted black }
    h1    { font-family: Arial,Helvetica,sans-serif }
    h2    { font-family: Arial,Helvetica,sans-serif; color: white; background: black }
    h3    { font-family: Arial,Helvetica,sans-serif }
    h4    { border-bottom: 1px dotted grey }
    pre span.issue { background: yellow }
EOF

  desc 'Scan the application for common security defects'
  task 'security' do
    scan, scm = perform_scan([LintFu::Rails::UnsafeFindChecker, LintFu::Rails::BuggyEagerLoadChecker])
    output_file = File.join(RAILS_ROOT, 'lint_security.html')
    write_report(scan, scm, output_file)
  end

  private

  def timed(activity)
    print activity, '...'
    t0 = Time.now.to_i
    yield
    t1 = Time.now.to_i
    dt = t1-t0
    if dt > 0
      puts "done (#{t1-t0} sec)"
    else
      puts "done"
    end
  end

  def perform_scan(controller_checkers)
    scan    = LintFu::Scan.new(RAILS_ROOT)
    scm     = LintFu::SourceControlProvider.for_directory(RAILS_ROOT)
    builder = nil
    context = nil

    #Build a model of the application we are scanning.
    timed("Build a model of the application") do
      builder = LintFu::Rails::ApplicationModelBuilder.new(RAILS_ROOT)
      context = builder.application
      raise LintFu::ProviderError.new("Unable to identify the source control provider for #{RAILS_ROOT}") unless scm
    end

    #Using the model we built, scan the controllers for security bugs.
    timed("Scan controllers") do
      controllers_dir = File.join(RAILS_ROOT, 'app', 'controllers')
      Dir.glob(File.join(controllers_dir, '**', '*.rb')).each do |filename|
        contents = File.read(filename)
        sexp = RubyParser.new.parse(contents)
        visitor = LintFu::GenericVisitor.new
        controller_checkers.each { |klass| visitor.observers << klass.new(scan, context, filename) }
        visitor.process(sexp)
      end
    end

    return [scan, scm]
  end

  def write_report(scan, scm, output_file)
    #Build map of contributors to issues they created
    timed("Prepare report") do
      @issues_by_author = Hash.new
      scan.issues.each do |issue|
        commit, author = scm.blame(issue.relative_file, issue.line)
        @issues_by_author[author] ||= []
        @issues_by_author[author] << issue
      end
      #Sort contributors in decreasing order of number of issues created
      @authors_by_issue_count = @issues_by_author.keys.sort { |x,y| @issues_by_author[y].size <=> @issues_by_author[x].size }

      @issues_by_class = Hash.new
      scan.issues.each do |issue|
        klass = issue.class
        @issues_by_class[klass] ||= []
        @issues_by_class[klass] << issue
      end

      #Build map of files to issues they contain
      @issues_by_file = Hash.new
      scan.issues.each do |issue|
        @issues_by_file[issue.relative_file] ||= []
        @issues_by_file[issue.relative_file] << issue
      end
      #Sort files in decreasing order of number of issues contained
      @files_by_issue_count = @issues_by_file.keys.sort { |x,y| @issues_by_file[y].size <=> @issues_by_file[x].size }
      #Sort files in increasing lexical order of path
      @files_by_name = @issues_by_file.keys.sort { |x,y| x <=> y }
    end

    #Write the report in HTML format
    timed("Write report") do
      output = File.open(output_file, 'w')
      x = Builder::XmlMarkup.new(:target => output, :indent => 0)
      x.html do |html|
        html.head do |head|
          head.title 'Rails Security Scan'
          head.style(STYLESHEET, :type=>'text/css')
        end
        html.body do |body|
          body.h1 'Summary'
          body.p "#{scan.issues.size} issues found."

          body.h2 'Issues by Type'
          body.table do |table|
            table.thead do |thead|
              thead.tr do |tr|
                tr.th 'Type'
                tr.th '#'
                tr.th 'Issues'
              end
              @issues_by_class.each_pair do |klass, issues|
                table.tr do |tr|
                  tr.td(klass.name.split('::').last.underscore.humanize)
                  tr.td(issues.size.to_s)
                  tr.td do |td|
                    issues.each do |issue|
                      td.a(issue.hash[0..4], :href=>"#issue_#{issue.hash}")
                      td.text!(' ')
                    end
                  end
                end
              end
            end
          end

          body.h2 'Issues by Contributor'
          body.table do |table|
            table.thead do |thead|
              thead.tr do |tr|
                tr.th 'Name'
                tr.th '#'
                tr.th 'Issues'
              end
            end
            table.tbody do |tbody|
              @authors_by_issue_count.each do |author|
                table.tr do |tr|
                  tr.td(author)
                  tr.td(@issues_by_author[author].size.to_s)
                  tr.td do |td|
                    @issues_by_author[author].each do |issue|
                      td.a(issue.hash[0..4], :href=>"#issue_#{issue.hash}")
                      td.text!(' ')
                    end
                  end
                end
              end
            end
          end

          body.h2 'Issues by File'
          body.table do |table|
            table.thead do |thead|
              thead.tr do |tr|
                tr.th 'File'
                tr.th '#'
                tr.th 'Issues'
              end
            end
            table.tbody do |tbody|
              @files_by_issue_count.each do |file|
                tbody.tr do |tr|
                  tr.td(file)
                  tr.td(@issues_by_file[file].size.to_s)
                  tr.td do |td|
                    @issues_by_file[file].each do |issue|
                      td.a(issue.hash[0..4], :href=>"#issue_#{issue.hash}")
                      td.text!(' ')
                    end
                  end
                end
              end
            end
          end

          body.h1 'Detailed Results'
          @files_by_name.each do |file|
            body.h2 file

            issues = @issues_by_file[file]
            issues = issues.to_a.sort { |x,y| x.line <=> y.line }
            issues.each do |issue|
              body.div(:class=>'issue', :id=>"issue_#{issue.hash}") do |div|
                div.h4 "#{issue.brief}, #{File.basename(issue.file)} line #{issue.line}"
                div.span(issue.detail, :class=>'detail')

                first   = issue.line-3
                first   = 1 if first < 1
                last    = issue.line + 3
                excerpt = scm.excerpt(issue.file, (first..last), :blame=>false)

                div.pre do |pre|
                  counter = first
                  excerpt.each do |line|
                    if counter == issue.line
                      pre.span(line, :class=>'issue')
                    else
                      pre.text! line
                    end
                    counter += 1
                  end
                end
              end
            end
          end

        end
      end
    end
  end
end
