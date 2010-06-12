module LintFu
  module Rails
    class ModelApplication
      include LintFu::ModelElement
      include LintFu::SuperModel

      def controllers
        submodels.select { |m| m.kind_of?(LintFu::ActionPack::ModelController) }
      end

      def models
        submodels.select { |m| m.kind_of?(LintFu::ActiveRecord::ModelModel) }
      end
    end
  end
end