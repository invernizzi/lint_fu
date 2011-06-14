module LintFu
  module SourceControl
    class Unknown < BaseProvider
      UNKNOWN_BLAME = ['unknown', 'unknown']
      def initialize(path)
        super(path)
      end

      # ==Return
      #  An array containing [author, commit_ref]
      def blame(file, line)
        UNKNOWN_BLAME
      end
    end
  end
end