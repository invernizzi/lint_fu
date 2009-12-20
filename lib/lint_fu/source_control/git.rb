module LintFu
  module SourceControl
    class Git < SourceControlProvider
      BLAME_REGEXP = /^(.*) \((.+) [0-9]{4}-[0-9]{1,2}-[0-9]{1,2}\s+([0-9]+)\)/

      def initialize(path)
        `git version`
        raise ProviderNotInstalled, self unless $?.success?

        dot_git = File.join(path, '.git')
        raise ProviderError.new(self, path) unless File.directory?(dot_git)
        @root = path
      end

      # ==Return
      #  An array containing [author, commit_ref]
      def blame(file, line)
        #commit, author, line_no,
        output = `git blame --date=short -w -L #{line} #{file}`
        match = BLAME_REGEXP.match(output)
        if $?.success? && match && (match[3].to_i == line)
          return [ match[1].strip, match[2].strip ]
        else
          raise ProviderError, output
        end
      end

      def excerpt(file, line, options={})
        blame   = options.has_key?(:blame)   ? options[:blame] : true
        context = options.has_key?(:context) ? options[:context] : 7

        Dir.chdir(@root) do
          start_line    = line - (context/2)
          start_line    = 1 if start_line < 1
          end_line      = line + (context/2)
          relative_path = File.relative_path(@root, file)

          output = `git blame --date=short #{blame ? '' : '-s'} -w -L #{start_line},#{end_line} #{relative_path} 2> /dev/null`
          return output if $?.success?

          #HACK: if git blame failed, assume we need to bound according to end of file
          file_length = `wc -l #{relative_path}`.split[0].to_i
          end_line = file_length
          output = `git blame --date=short #{blame ? '' : '-s'} -w -L #{start_line},#{end_line} #{relative_path}`
          return output if $?.success?

          raise ProviderError.new(output)
        end
      end
    end
  end
end