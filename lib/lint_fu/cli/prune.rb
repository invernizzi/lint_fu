module LintFu::CLI
  class Prune < BaseCommand
    RUBY_FILE_EXT = /\.rb[a-z]?/

    def run
      #Build a model of the application we are scanning.
      timed("Build a model of the application") do
        builder = LintFu::Plugins::Rails.context_builder_for(self.app_root)
        builder.build
        @application = builder.eide.first
      end

      #Using the model we built, scan the controllers for security bugs.
      timed("Scan the application") do
        @scan = LintFu::Core::Scan.new(self.app_root)
        #TODO generalize/abstract this, same as we did for context builders
        builder = LintFu::Plugins::Rails.issue_builder_for(self.app_root)
        builder.build(@application, @scan)
      end

      blessings       = []
      blessing_ranges = nil
      useless         = []

      timed("Find all annotations") do
        recurse(self.app_root, blessings)

        blessing_ranges = blessings.map do |triple|
          file, line, comment = triple[0], triple[1], triple[2]
          next LintFu::Core::FileRange.new(file, line, line, comment)
        end
      end

      timed("Cross-check annotations against issues") do
        issue_ranges = @scan.issues.map do |issue|
          issue.sexp.preceding_comment_range
        end
        issue_ranges.compact!

        blessing_ranges.each do |b|
          useless << b unless issue_ranges.any? { |r| r.include?(b) }
        end
      end

      say "Found #{useless.size} extraneous annotations (out of #{blessings.size} total)."

      useless.each do |range|
        filename = File.relative_path(self.app_root, range.filename)
        say "#{filename}:#{range.line}"
      end

      say "WARNING: I did not actually prune these; you need to do it yourself!!"

      return 0
    end

    protected

    def recurse(dir, results)
      dir = File.expand_path(dir)
      Dir.glob(File.join(dir, '*')).each do |dirent|
        if File.directory?(dirent)
          recurse(dirent, results)
        elsif dirent =~ RUBY_FILE_EXT
          find_blessings(dirent, File.readlines(dirent), results)
        end
      end
    end

    def find_blessings(file, lines, results)
      lines.each_with_index do |line, i|
        blessing = LintFu::Core::Blessing.parse(line)
        next if blessing.empty?
        results << [file, i+1, line] 
      end
    end
  end
end