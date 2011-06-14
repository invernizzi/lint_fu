module LintFu::Reports
  class TextWriter < BaseWriter
    def generate(output_stream)
      counter = 1

      @issues.each do |issue|
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