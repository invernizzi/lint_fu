module LintFu
  module SourceControl
    class BaseProvider
      @@subclasses = Set.new

      # Inherited callback to ensure this base class knows about all derived classes.
      def self.inherited(base)
        @@subclasses << base
      end

      def self.subclasses
        @@subclasses
      end

      def initialize(path)
        @root = path
      end

      def excerpt(file, range, options={})
        blame   = options.has_key?(:blame)   ? options[:blame] : true
        raise ProviderError, "Blame is not supported for this source control provider" if blame

        Dir.chdir(@root) do
          start_line = range.first
          end_line   = range.last
          io         = File.open(File.relative_path(@root, file), 'r')
          lines      = io.readlines
          return lines[(start_line-1)..(end_line-1)]
        end
      end
    end
  end
end