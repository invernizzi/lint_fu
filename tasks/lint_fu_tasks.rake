require File.expand_path(File.join(File.dirname(__FILE__), '..', 'init.rb'))

#Only define the Rake tasks if the plugin loaded successfully
if defined?(LintFu)
  desc "Perform static analysis of the source code to find common security and correctness issues."
  task :lint do
    CHECKERS = [LintFu::Rails::UnsafeFindChecker, LintFu::Rails::BuggyEagerLoadChecker, LintFu::Rails::SqlInjectionChecker]
    scan, scm = perform_scan(CHECKERS)

    if scan.issues.empty?
      puts "Clean scan: no issues found. Skipping report."
      exit(0)
    end

    #Enable seamless CruiseControl.rb integration: write our report to the CC build artifacts folder
    output_dir = ENV['CC_BUILD_ARTIFACTS'] || RAILS_ROOT
    mkdir_p output_dir unless File.directory?(output_dir)

    #Use a filename (or STDOUT) for our report that corresponds to its format
    case (flavor = ENV['FORMAT'] || 'html')
      when 'html'
        output_name = File.join(output_dir, 'lint.html')
        output      = File.open(output_name, 'w')
      when 'text'
        output = STDOUT
      else
        puts "Unrecognized output format #{flavor} (undefined type #{typename})"
        exit -1
    end

    typename = "#{flavor}_report".camelize
    klass    = LintFu.const_get(typename.to_sym)

    timed("Generate report") do
      klass.new(scan, scm).generate(output)
      output.close
    end

    system("open #{output_name}") if (output != STDOUT && STDOUT.tty?)
    exit( [scan.issues.size, 255].min )
  end

  private

  def timed(activity)
    print activity, '...'
    STDOUT.flush
    t0 = Time.now.to_i
    yield
    t1 = Time.now.to_i
    dt = t1-t0
    if dt > 0
      puts "done (#{t1-t0} sec)"
      STDOUT.flush
    else
      puts "done"
      STDOUT.flush
    end
  end

  def perform_scan(controller_checkers)
    scan    = LintFu::Scan.new(RAILS_ROOT)
    scm     = LintFu::SourceControlProvider.for_directory(RAILS_ROOT)
    builder = nil
    context = nil

    #Build a model of the application we are scanning.
    timed("Build a model of the application") do
      builder = LintFu::Rails::ApplicationModelBuilder.new(RAILS_ROOT)
      context = builder.application
      raise LintFu::ProviderError.new("Unable to identify the source control provider for #{RAILS_ROOT}") unless scm
    end

    #Using the model we built, scan the controllers for security bugs.
    timed("Scan controllers") do
      controllers_dir = File.join(RAILS_ROOT, 'app', 'controllers')
      Dir.glob(File.join(controllers_dir, '**', '*.rb')).each do |filename|
        contents = File.read(filename)
        parser = RubyParser.new
        sexp = parser.parse(contents, filename)
        visitor = LintFu::GenericVisitor.new
        controller_checkers.each { |klass| visitor.observers << klass.new(scan, context, filename) }
        visitor.process(sexp)
      end
    end

    return [scan, scm]
  end
end
