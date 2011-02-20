module LintFu::Plugins
  module Rails
    class ModelApplicationBuilder < LintFu::ModelElementBuilder
      def initialize(fs_root)
        super
        @application = ModelApplication.new(fs_root)
        self.model_elements << @application
      end

      def build
        models_dir = File.join(@application.fs_root, 'app', 'models')
        builder = LintFu::Plugins::ActiveRecord::ModelModelBuilder.new
        #TODO ensure the Rails app is using ActiveRecord
        Dir.glob(File.join(models_dir, '**', '*.rb')).each do |f|
          sexp = LintFu::Parser.parse_ruby(f)
          builder.process(sexp)
        end
        builder.model_elements.each { |elem| @application.add_submodel(elem) }

        controllers_dir = File.join(@application.fs_root, 'app', 'controllers')
        builder = ActionPack::ModelControllerBuilder.new
        Dir.glob(File.join(controllers_dir, '**', '*.rb')).each do |f|
          sexp = LintFu::Parser.parse_ruby(f)
          sexp.file = f
          builder.process(sexp)
        end
        builder.model_elements.each { |elem| @application.add_submodel(elem) }
      end
    end
  end
end