module LintFu
  module Rails
    class ApplicationModel
      include LintFu::ModelElement
      include LintFu::SuperModel
      
      def initialize
      end

      def models
        submodels.select { |m| m.kind_of?(LintFu::ActiveRecord::ModelModel) }
      end
    end
  end
end