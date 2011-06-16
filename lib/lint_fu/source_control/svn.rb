module LintFu
  module SourceControl
    class Svn < BaseProvider
      SVN_BLAME_REGEXP = /^\s*([^\s]+)\s+.([^\s]+)\s+.*/

      def initialize(path)
        super(path)
        #check that svn is installed, and the current dir is versioned
        `svn --version`
        raise ProviderNotInstalled, self unless $?.success?
        dot_svn = File.join(path, '.svn')
        raise ProviderError.new(self, path) unless File.directory?(dot_svn)
      end

      # ==Return
      #  An array containing [author, commit_ref]
      def blame(file, line_num)
        #revision, author
        output = `svn blame #{file}`
        #line_num starts at line 1
        line = output.split("\n")[line_num - 1]
        match = SVN_BLAME_REGEXP.match(line)
        if $?.success? && match
          return [match[1].strip, match[2].strip]
        else
          raise ProviderError, output
        end
      end

      def excerpt(file, range, options={})
        blame   = options.has_key?(:blame) ? options[:blame] : true

        return super unless blame

        Dir.chdir(@root) do
          start_line = range.first
          end_line   = range.last
          relative_path = File.relative_path(@root, file)

          lines = `svn blame -v #{relative_path} 2> /dev/null`.split('\n')[(start_line - 1)..(end_line - 1)]
          output = ''.join(lines)
          return output if $?.success?

          #I've never seen a case where this is necessary yet
          return "Need to code workaround a la git"
        end
      end
    end
  end
end
