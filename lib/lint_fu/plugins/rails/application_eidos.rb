module LintFu::Plugins
  module Rails
    class ApplicationEidos
      attr_reader :fs_root
      
      include LintFu::Core::EidosContainer

      def initialize(fs_root)
        @fs_root = fs_root
      end

      def controllers
        eide.select { |m| m.kind_of?(LintFu::Plugins::ActionPack::ControllerEidos) }
      end

      def models
        eide.select { |m| m.kind_of?(LintFu::Plugins::ActiveRecord::ModelEidos) }
      end
    end
  end
end