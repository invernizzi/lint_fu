
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
          include_external_javascripts(head)
          include_external_stylesheets(head)
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
                  sample_issue = issues.first
                  tr.td(sample_issue.brief)
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
                div.h4 do |h4|
                  href = "#TB_inline?width=800&height=600&inlineId=#{id_for_issue_class(issue.class)}"
                  h4.a(issue.brief, :href=>href.to_sym, :title=>issue.brief, :class=>'thickbox')
                  h4.text! ", #{File.basename(issue.file)}:#{issue.line}"
                end
                div.span(issue.detail, :class=>'detail')

                first   = issue.line-3
                first   = 1 if first < 1
                last    = issue.line + 3
                excerpt = scm.excerpt(issue.file, (first..last), :blame=>false)
                highlighted_code_snippet(div, excerpt, first, issue.line)
              end
            end
          end

          body.h1 'Reference Information'
          @issues_by_class.values.each do |array|
            sample_issue = array.first
            body.h2 sample_issue.brief
            body.div(:id=>id_for_issue_class(sample_issue.class)) do |div|
              div << RedCloth.new(sample_issue.reference_info).to_html 
            end
          end

          activate_syntax_highlighter(body)
        end
      end
    end

    private

    def highlighted_code_snippet(parent, snippet, first_line, highlight)
      parent.pre(snippet, :class=>"brush: ruby; first-line: #{first_line}; highlight: [#{highlight}]")
    end

    def include_external_javascripts(head)
      head.script(:src=>'http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js', :type=>'text/javascript')
      head.script(:src=>'http://gdata-samples.googlecode.com/svn/!svn/bc/178/trunk/oauth_playground/js/thickbox-compressed.js', :type=>'text/javascript')
      head.script(:src=>'http://xregexp.com/xregexp-min.js', :type=>'text/javascript')
      head.script(:src=>'http://bitbucket.org/alexg/syntaxhighlighter/raw/378fedcc2759/scripts/shCore.js', :type=>'text/javascript')
      head.script(:src=>'http://bitbucket.org/alexg/syntaxhighlighter/raw/378fedcc2759/scripts/shBrushRuby.js', :type=>'text/javascript')
    end

    def include_external_stylesheets(head)
      head.link(:rel=>'stylesheet', :type=>'text/css', :href=>'http://gdata-samples.googlecode.com/svn/!svn/bc/178/trunk/oauth_playground/css/thickbox.css')
      head.link(:rel=>'stylesheet', :type=>'text/css', :href=>'http://bitbucket.org/alexg/syntaxhighlighter/raw/378fedcc2759/styles/shCore.css')
      head.link(:rel=>'stylesheet', :type=>'text/css', :href=>'http://bitbucket.org/alexg/syntaxhighlighter/raw/378fedcc2759/styles/shThemeDefault.css')
    end

    def id_for_issue_class(klass)
      "reference_#{klass.name.split('::')[-1].underscore}"      
    end

    def activate_syntax_highlighter(body)
      body.script('SyntaxHighlighter.all()', :type=>'text/javascript')
    end
  end

  class TextReport < Report
    def generate(output_stream)
      counter = 1

      scan.issues.each do |issue|
        #commit, author = scm.blame(issue.relative_file, issue.line)
        output_stream.puts " #{counter}) Failure:"
        output_stream.puts "#{issue.brief}, #{issue.relative_file}:#{issue.line}"
        output_stream.puts
        output_stream.puts
        counter += 1
      end
    end
  end
end