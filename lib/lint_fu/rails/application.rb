module LintFu
  module Rails
    class Application < ModelElement
      attr_reader :models

      def initialize
        @models = Set.new
      end
    end

    class ApplicationBuilder
      attr_reader :application
      
      def initialize(rails_root)
        @application = Application.new

        models_dir = File.join(rails_root, 'app', 'models')
        model_builder = ActiveRecord::ModelBuilder.new

        #Parse all of the models and build ModelElements for each
        #TODO ensure the Rails app is using ActiveRecord
        Dir.glob(File.join(models_dir, '**', '*.rb')).each do |f|
          contents = File.read(f)
          sexp = RubyParser.new.parse(contents)
          model_builder.process(sexp)
        end

        model_builder.model_elements.each { |elem| @application.models << elem }
      end

    end
  end
end