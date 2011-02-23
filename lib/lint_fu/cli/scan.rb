module LintFu::CLI
  class Scan < Command
    def run(options)
      app_root = File.expand_path('.')
      @scm = LintFu::SourceControlProvider.for_directory(app_root)
      raise LintFu::ProviderError.new("Unable to identify the source control provider for #{app_root}") unless @scm

      #Build a model of the application we are scanning.
      timed("Build a model of the application") do
        builder = LintFu::Plugins::Rails.context_builder_for(app_root)
        builder.build
        @application = builder.eide.first
      end

      #Using the model we built, scan the controllers for security bugs.
      timed("Scan the application") do
        @scan = LintFu::Scan.new(app_root)
        builder = LintFu::Plugins::Rails.issue_builder_for(app_root)
        builder.build(@application, @scan)
      end

      @genuine_issues = @scan.issues.select { |i| !@scan.blessed?(i) }
      if @genuine_issues.empty?
        puts "Clean scan: no issues found. Skipping report."
        exit(0)
      end

      #CruiseControl.rb integration: write our report to the CC build artifacts folder
      output_dir = ENV['CC_BUILD_ARTIFACTS'] || app_root
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

      return retval
    end
  end
end