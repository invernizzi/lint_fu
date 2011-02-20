module LintFu::Plugins
  module Rails
    class ModelApplication
      attr_reader :fs_root
      
      include LintFu::SuperModel

      def initialize(fs_root)
        @fs_root = fs_root
      end

      def controllers
        submodels.select { |m| m.kind_of?(LintFu::Plugins::ActionPack::ModelController) }
      end

      def models
        submodels.select { |m| m.kind_of?(LintFu::Plugins::ActiveRecord::ModelModel) }
      end
    end
  end
end