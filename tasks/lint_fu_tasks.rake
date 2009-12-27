require File.expand_path(File.join(File.dirname(__FILE__), '..', 'init.rb'))

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
  
  desc "Scan the application for common security defects"
  task "security" do
    scan    = LintFu::Scan.new(RAILS_ROOT)
    scm     = LintFu::SourceControlProvider.for_directory(RAILS_ROOT)

    #Build a model of the application we are scanning.
    t0 = Time.now.to_i
    puts "Building a model of the application..."
    builder = LintFu::Rails::ApplicationModelBuilder.new(RAILS_ROOT)
    context = builder.application
    t1 = Time.now.to_i
    puts "(#{t1 - t0} sec) done"; puts
    raise LintFu::ProviderError.new("Unable to identify the source control provider for #{RAILS_ROOT}") unless scm

    #Using the model we built, scan the controllers for security bugs.
    puts "Scanning controllers..."
    t0 = Time.now.to_i
    controllers_dir = File.join(RAILS_ROOT, 'app', 'controllers')
    Dir.glob(File.join(controllers_dir, '**', '*.rb')).each do |f|
      contents = File.read(f)
      sexp = RubyParser.new.parse(contents)
      LintFu::Rails::ControllerVisitor.new(scan, context, f).process(sexp)      
    end
    t1 = Time.now.to_i
    puts "(#{t1 - t0} sec) done"; puts

    #Build map of contributors to issues they created
    t0 = Time.now.to_i
    puts "Preparing report..."
    authors = Hash.new
    scan.issues.each do |issue|
      commit, author = scm.blame(issue.relative_file, issue.line)
      authors[author] ||= Set.new
      authors[author] << issue
    end
    #Sort contributors in decreasing order of number of issues created
    authors_by_issue_count = authors.keys.sort { |x,y| authors[y].size <=> authors[x].size }

    #Build map of files to issues they contain
    files = Hash.new
    scan.issues.each do |issue|
      files[issue.relative_file] ||= Set.new
      files[issue.relative_file] << issue
    end
    #Sort files in decreasing order of number of issues contained
    files_by_issue_count = files.keys.sort { |x,y| files[y].size <=> files[x].size }
    #Sort files in increasing lexical order of path
    files_by_name = files.keys.sort { |x,y| x <=> y }
    t1 = Time.now.to_i
    puts "(#{t1 - t0} sec) done"; puts

    puts "Writing report..."
    output_path = File.join(RAILS_ROOT, 'lint_security.html')
    output = File.open(output_path, 'w')
    x = Builder::XmlMarkup.new(:target => output, :indent => 0)
    x.html do |html|
      html.head do |head|
        head.title 'Rails Security Scan'
        head.style(STYLESHEET, :type=>'text/css')
      end
      html.body do |body|
        body.h1 'Summary'
        body.p "#{scan.issues.size} issues found."

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
            files_by_issue_count.each do |file|
              tbody.tr do |tr|
                tr.td(file)
                tr.td(files[file].size.to_s)
                tr.td do |td|
                  files[file].each do |issue|
                    td.a(issue.hash[0..4], :href=>"#issue_#{issue.hash}")
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
            authors_by_issue_count.each do |author|
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
        end

        body.h1 'Detailed Results'
        files_by_name.each do |file|
          body.h2 file
          
          issues = files[file]
          issues = issues.to_a.sort { |x,y| x.line <=> y.line }
          issues.each do |issue|
            body.div(:class=>'issue', :id=>"issue_#{issue.hash}") do |div|
              div.h4 "#{issue.brief}, line #{issue.line}"
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
    puts "(#{t1 - t0} sec) done"; puts
  end

  private
  def word_wrap(str, len=60)
    str.gsub(/\t/,"     ").gsub(/.{1,78}(?:\s|\Z)/){($& + 5.chr).gsub(/\n\005/,"\n").gsub(/\005/,"\n")}
  end
end
