require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'init.rb'))

#Only define the Rake tasks if the plugin loaded successfully
if defined?(LintFu)
  desc "Perform static analysis of the source code to find common security and correctness issues."
  task :lint do
    @scm    = LintFu::SourceControlProvider.for_directory(RAILS_ROOT)

    #Build a model of the application we are scanning.
    timed("Build a model of the application") do
      builder = LintFu::Rails::ModelApplicationBuilder.new(RAILS_ROOT)
      @application = builder.model_elements[0]
      raise LintFu::ProviderError.new("Unable to identify the source control provider for #{RAILS_ROOT}") unless @scm
    end

    #Using the model we built, scan the controllers for security bugs.
    timed("Scan the application") do
      builder = LintFu::Rails::ScanBuilder.new(RAILS_ROOT)
      @scan = builder.scan(@application)
    end

    @genuine_issues = @scan.issues.select { |i| !@scan.blessed?(i) }
    if @genuine_issues.empty?
      puts "Clean scan: no issues found. Skipping report."
      exit(0)
    end

    #Enable seamless CruiseControl.rb integration: write our report to the CC build artifacts folder
    output_dir = ENV['CC_BUILD_ARTIFACTS'] || RAILS_ROOT
    mkdir_p output_dir unless File.directory?(output_dir)

    flavor   = ENV['FORMAT'] || 'html'
    typename = "#{flavor}_report".camelize

    #Use a filename (or STDOUT) for our report that corresponds to its format
    case flavor
      when 'html'
        output_name = File.join(output_dir, 'lint.html')
        output      = File.open(output_name, 'w')
      when 'text'
        output = STDOUT
      else
        puts "Unrecognized output format #{flavor} (undefined type #{typename})"
        exit -1
    end

    klass    = LintFu.const_get(typename.to_sym)

    timed("Generate report") do
      klass.new(@scan, @scm, @genuine_issues).generate(output)
      output.close
    end

    #Support automation jobs that need to distinguish between failure due to
    #broken environment and failure to due issues that were genuinely found by
    #the lint task.
    if ENV['STATUS_IF_ISSUES']
      if(@genuine_issues.size > 0)
        retval = ENV['STATUS_IF_ISSUES'].to_i
      else
        retval = 0
      end
    else
      retval = [@genuine_issues.size, 255].min
    end

    system("open #{output_name}") if (output != STDOUT && STDOUT.tty?)

    exit( retval )
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
