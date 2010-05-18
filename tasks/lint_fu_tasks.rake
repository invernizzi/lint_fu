require File.expand_path(File.join(File.dirname(__FILE__), '..', 'init.rb'))

#Only define the Rake tasks if the plugin loaded successfully
if defined?(LintFu)
  desc "Perform static analysis of the source code to find common security and correctness issues."
  task :lint do
    @scm    = LintFu::SourceControlProvider.for_directory(RAILS_ROOT)

    #Build a model of the application we are scanning.
    timed("Build a model of the application") do
      builder = LintFu::Rails::ApplicationModelBuilder.new(RAILS_ROOT)
      @application = builder.model_elements[0]
      raise LintFu::ProviderError.new("Unable to identify the source control provider for #{RAILS_ROOT}") unless @scm
    end

    #Using the model we built, scan the controllers for security bugs.
    timed("Scan the application") do
      @scan = @application.perform_scan
    end

    if @scan.genuine_issues.empty?
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
      klass.new(@scan, @scm).generate(output)
      output.close
    end

    system("open #{output_name}") if (output != STDOUT && STDOUT.tty?)
    exit( [@scan.genuine_issues.size, 255].min )
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
end
