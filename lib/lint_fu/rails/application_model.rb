module LintFu
  module Rails
    class ApplicationModel
      include LintFu::ModelElement
      include LintFu::SuperModel

      attr_reader :fs_root
      
      def initialize(fs_root)
        @fs_root = fs_root
      end

      def controllers
        submodels.select { |m| m.kind_of?(LintFu::ActionPack::ModelController) }
      end

      def models
        submodels.select { |m| m.kind_of?(LintFu::ActiveRecord::ModelModel) }
      end

      def perform_scan
        scan    = LintFu::Scan.new(self.fs_root)

        models_dir      = File.join(self.fs_root, 'app', 'models')
        controllers_dir = File.join(self.fs_root, 'app', 'controllers')
        views_dir       = File.join(self.fs_root, 'app', 'views')

        #Scan controllers
        Dir.glob(File.join(controllers_dir, '**', '*.rb')).each do |filename|
          contents = File.read(filename)
          parser = RubyParser.new
          sexp = parser.parse(contents, filename)
          visitor = LintFu::Visitor.new
          visitor.observers << BuggyEagerLoadChecker.new(scan, self, filename)
          visitor.observers << SqlInjectionChecker.new(scan, self, filename)
          visitor.observers << UnsafeFindChecker.new(scan, self, filename)
          visitor.process(sexp)
        end

        return scan
      end
    end
  end
end