module LintFu
  class Report
    attr_reader :scan, :scm
    
    def initialize(scan, scm)
      @scan = scan
      @scm = scm
    end

    def generate(output_stream)
      raise NotImplemented
    end
  end

  class HtmlReport < Report
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

    def generate(output_stream)
      #Build map of contributors to issues they created

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

      #Write the report in HTML format
      x = Builder::XmlMarkup.new(:target => output_stream, :indent => 0)
      x.html do |html|
        html.head do |head|
          head.title 'Static Analysis Results'
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

  class TextReport < Report
    def generate(output_stream)
      counter = 1

      scan.issues.each do |issue|
        commit, author = scm.blame(issue.relative_file, issue.line)
        output_stream.puts "#{counter}) Error:"
        output_stream.puts issue.brief
        output_stream.puts issue.detail
        output_stream.puts "Introduced by #{author} in #{commit}"
        output_stream.puts
        output_stream.puts
        counter += 1
      end
    end
  end
end