module LintFu::CLI
  # Base class for CLI commands
  class Command
    def initialize(options)
      @options = options
    end

    def run
      raise NotImplementedError
    end

    protected

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
    rescue Exception => e
      print 'error!' unless e.is_a?(SignalException)
      puts
      raise e
    end
  end
end