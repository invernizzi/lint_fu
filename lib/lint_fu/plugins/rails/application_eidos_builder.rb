module LintFu::Plugins
  module Rails
    class ApplicationEidosBuilder < LintFu::Core::EidosBuilder
      def initialize(fs_root)
        super
        @application = ApplicationEidos.new(fs_root)
        self.eide << @application
      end

      def build
        models_dir = File.join(@application.fs_root, 'app', 'models')
        builder = LintFu::Plugins::ActiveRecord::ModelEidosBuilder.new
        #TODO ensure the Rails app is using ActiveRecord
        Dir.glob(File.join(models_dir, '**', '*.rb')).each do |f|
          sexp = LintFu::Parser.parse_ruby(f)
          builder.process(sexp)
        end
        builder.eide.each { |elem| @application.add_eidos(elem) }

        controllers_dir = File.join(@application.fs_root, 'app', 'controllers')
        builder = ActionPack::ControllerEidosBuilder.new
        Dir.glob(File.join(controllers_dir, '**', '*.rb')).each do |f|
          sexp = LintFu::Parser.parse_ruby(f)
          sexp.file = f
          builder.process(sexp)
        end
        builder.eide.each { |elem| @application.add_eidos(elem) }
      end
    end
  end
end