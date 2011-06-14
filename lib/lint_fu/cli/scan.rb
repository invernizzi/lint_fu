require 'pathname'

module LintFu::CLI
  class Scan < BaseCommand
    REPORT_FORMATS = {
        'html'    => LintFu::Reports::HtmlWriter,
        'text'    => LintFu::Reports::TextWriter,
        'marshal' => LintFu::Reports::MarshalWriter
    }

    # The marshal format is not portable; it's only used for functional tests
    VISIBLE_FORMATS = REPORT_FORMATS.keys - ['marshal']

    def initialize(options)
      #Special-case options handling: if neither report nor output was supplied, assume the
      #user wants an HTML report output to lint_fu.html in the current directory.
      unless options[:format] || options[:output]
        options[:format] ||= 'html'
        options[:output] = 'lint_fu.html'
      end

      super(options)
    end

    def run
      #Build a model of the application we are scanning.
      timed("Build a model of the application") do
        builder = LintFu::Plugins::Rails.context_builder_for(self.app_root)

        unless builder
          say "Cannot determine context builder for #{File.basename(self.app_root)}."
          say "Either this application uses a framework that is unsupported by LintFu,"
          say "or a bug is preventing us from recognizing the application framework."
          say "Sorry!"
          exit(-1)
        end

        builder.build
        @application = builder.eide.first
      end

      #Using the model we built, scan the controllers for security bugs.
      timed("Scan the application") do
        @scan = LintFu::Core::Scan.new(self.app_root)
        #TODO generalize/abstract this, same as we did for context builders
        builder = LintFu::Plugins::Rails.issue_builder_for(self.app_root)
        builder.build(@application, @scan)
      end

      report_klass = REPORT_FORMATS[@options[:format]]
      output_name = Pathname.new(@options[:output]) if @options[:output]

      if output_name && !output_name.absolute?
        # Magic CCRb integration
        # TODO: remove magic, it's not needed!
        output_dir = Pathname.new(ENV['CC_BUILD_ARTIFACTS'] || self.app_root)
        output_name = output_dir + output_name
      end

      if output_name
        output_dir = output_name.dirname
        FileUtils.mkdir_p output_dir unless File.directory?(output_dir)
        output = File.open(output_name, 'w')
      else
        output = STDOUT
      end

      timed("Generate report") do
        @genuine_issues = @scan.issues.select { |i| !@scan.blessed?(i) }
        report_klass.new(@scan, self.scm, @genuine_issues).generate(output)
        output.close
      end

      #Support automation jobs that need to distinguish between failure due to
      #broken environment and failure to due issues that were genuinely found by
      #the lint task.
      if (@genuine_issues.size > 0) && @options[:fail]
        retval = [@genuine_issues.size, 255].min
      else
        retval = 0
      end

      system("open #{output_name}") if (output != STDOUT) && STDOUT.tty?

      return retval
    end
  end
end