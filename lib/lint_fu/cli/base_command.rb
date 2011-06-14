module LintFu::CLI
  # Base class for CLI commands
  class BaseCommand
    @@subclasses = Set.new

    # Inherited callback to ensure this base class knows about all derived classes.
    def self.inherited(base)
      @@subclasses << base
    end

    def self.subclasses
      @@subclasses
    end

    def initialize(options)
      @options = options
    end

    def run
      raise NotImplementedError
    end

    protected

    def app_root
      File.expand_path('.')      
    end

    def scm
      @scm ||= LintFu::SourceControl.for_directory(app_root)
      raise LintFu::SourceControl::ProviderError.new("Unable to identify the source control provider for #{app_root}") unless @scm
      @scm
    end

    def say(*args)
      puts(*args) unless @options[:quiet]
    end

    def timed(activity)
      unless @options[:quiet]
        print(activity, '...')
        STDOUT.flush
      end

      t0 = Time.now.to_f
      yield
      t1 = Time.now.to_f

      unless @options[:quiet]
        dt = (t1-t0).to_i
        if dt > 0
          puts "done (#{dt} sec)"
        else
          puts "done"
        end
      end
    end
  end
end