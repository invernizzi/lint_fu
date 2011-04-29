module LintFu::Plugins
  module Rails
    class IssueBuilder
      attr_reader :fs_root

      def initialize(fs_root)
        @fs_root = fs_root
      end

      def build(context, scan)
        models_dir      = File.join(scan.fs_root, 'app', 'models')
        controllers_dir = File.join(scan.fs_root, 'app', 'controllers')
        views_dir       = File.join(scan.fs_root, 'app', 'views')

        #Scan controllers
        Dir.glob(File.join(controllers_dir, '**', '*.rb')).each do |filename|
          sexp = LintFu::Parser.parse_ruby(filename)
          visitor = LintFu::Visitor.new
          visitor.observers << BuggyEagerLoadChecker.new(scan, context, filename)
          visitor.observers << SqlInjectionChecker.new(scan, context, filename)
          visitor.observers << UnsafeFindChecker.new(scan, context, filename)
          visitor.process(sexp)
        end

        #Scan models
        Dir.glob(File.join(models_dir, '**', '*.rb')).each do |filename|
          sexp = LintFu::Parser.parse_ruby(filename)
          visitor = LintFu::Visitor.new
          visitor.observers << SqlInjectionChecker.new(scan, context, filename, 0.2)
          visitor.observers << UnsafeFindChecker.new(scan, context, filename)
          visitor.process(sexp)          
        end
      end
    end
  end
end