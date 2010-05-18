module LintFu
  module Rails
    class ApplicationModelBuilder < ModelElementBuilder
      def initialize(fs_root)
        super()
        
        application = ApplicationModel.new(fs_root)

        models_dir = File.join(fs_root, 'app', 'models')
        builder = ActiveRecord::ModelModelBuilder.new
        #TODO ensure the Rails app is using ActiveRecord
        Dir.glob(File.join(models_dir, '**', '*.rb')).each do |f|
          contents = File.read(f)
          sexp = RubyParser.new.parse(contents)
          sexp.file = f
          builder.process(sexp)
        end
        builder.model_elements.each { |elem| application.add_submodel(elem) }

        controllers_dir = File.join(fs_root, 'app', 'controllers')
        builder = ActionPack::ModelControllerBuilder.new
        Dir.glob(File.join(controllers_dir, '**', '*.rb')).each do |f|
          contents = File.read(f)
          sexp = RubyParser.new.parse(contents)
          sexp.file = f
          builder.process(sexp)
        end
        builder.model_elements.each { |elem| application.add_submodel(elem) }

        self.model_elements << application        
      end
    end
  end
end