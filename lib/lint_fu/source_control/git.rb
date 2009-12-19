module LintFu
  module SourceControl
    class Git < SourceControlProvider
      def initialize(path)
        `git version`
        raise ProviderNotInstalled, self unless $?.success?

        dot_git = File.join(path, '.git')
        raise ProviderError.new(self, path) unless File.directory?(dot_git)
        @root = path
      end

      def excerpt(file, line, options)
        blame   = options[:blame] || true
        context = options[:context] || 3

        Dir.chdir(root) do
          #find relative_path
          start_line    = line - (context/2)
          end_line      = line + (context/2)
          relative_path = File.relative_path(@root, file)
          return `git blame --date=short -wL #{start_line},#{end_line} #{relative_path}`
        end
      end
    end
  end
end