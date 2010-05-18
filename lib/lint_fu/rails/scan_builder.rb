module LintFu
  module Rails
    class ScanBuilder
      attr_reader :fs_root

      def initialize(fs_root)
        @fs_root = fs_root
      end

      def scan(context)
        scan    = LintFu::Scan.new(@fs_root)

        models_dir      = File.join(@fs_root, 'app', 'models')
        controllers_dir = File.join(@fs_root, 'app', 'controllers')
        views_dir       = File.join(@fs_root, 'app', 'views')

        #Scan controllers
        Dir.glob(File.join(controllers_dir, '**', '*.rb')).each do |filename|
          contents = File.read(filename)
          parser = RubyParser.new
          sexp = parser.parse(contents, filename)
          visitor = LintFu::Visitor.new
          visitor.observers << BuggyEagerLoadChecker.new(scan, context, filename)
          visitor.observers << SqlInjectionChecker.new(scan, context, filename)
          visitor.observers << UnsafeFindChecker.new(scan, context, filename)
          visitor.process(sexp)
        end

        #Scan models
        Dir.glob(File.join(models_dir, '**', '*.rb')).each do |filename|
          contents = File.read(filename)
          parser = RubyParser.new
          sexp = parser.parse(contents, filename)
          visitor = LintFu::Visitor.new
          visitor.observers << SqlInjectionChecker.new(scan, context, filename, 0.2)
          visitor.process(sexp)          
        end

        return scan
      end
    end
  end
end