module LintFu
  module Rails
    class ApplicationModel < ModelElement
      acts_as_supermodel
      
      def initialize
      end

      def models
        submodels.select { |m| m.kind_of?(LintFu::ActiveRecord::ModelModel) }
      end
    end
  end
end