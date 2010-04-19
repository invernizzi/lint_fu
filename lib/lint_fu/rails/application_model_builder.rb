module LintFu
  module Rails
    class ApplicationModelBuilder
      attr_reader :application

      def initialize(rails_root)
        @application = ApplicationModel.new

        models_dir = File.join(rails_root, 'app', 'models')
        model_builder = ActiveRecord::ModelModelBuilder.new

        #Parse all of the models and build ModelElements for each
        #TODO ensure the Rails app is using ActiveRecord
        Dir.glob(File.join(models_dir, '**', '*.rb')).each do |f|
          contents = File.read(f)
          sexp = RubyParser.new.parse(contents)
          sexp.file = f
          model_builder.process(sexp)
        end

        model_builder.model_elements.each { |elem| @application.add_submodel(elem) }
      end
    end
  end
end