module LintFu::Plugins
  module Rails
    class LogInformationLeak < LintFu::Core::Issue
      def detail
        "If a bad guy saw this log entry, would he gain something?"
      end

      def reference_info
        return <<EOF
h4. What is it?

When sensitive data is written to a log stream, it becomes impossible to know
where the data will copied or transmitted to. This creates a very dangerous
situation and allows data to be stolen with no obvious signs of an attack.

h4. When does it happen?

Whenever a log entry contains dynamic information, it *might* be the site of
an information leak.

bc. logger.info("Successful login with \#{params[:password]}")
logger.error("The secret agent's name is \#{user.name}")

h4. How do I fix it?

Think carefully whenever you write information to a log. Try to limit the information to
things that are available to the developers and operations people you trust. Remember that
your log data will be seen by everyone in your project/team/company, and in the worst case
the data may be stolen and viewed by a *bad guy*!!

EOF
      end
    end

    # Visit a Rails controller looking for troublesome stuff
    class LogInformationLeakChecker < LintFu::Core::Checker
      LOGGER_CALL_REGEXP     = /^log(ger)?/
      LOG_METHOD_CALL_REGEXP = /debug|info|warn|warn(ing)?|err(or)?|fatal/
      #sexp:: s(:call, <target>, <method_name>, s(:arglist))
      # s(:call, s(:call, nil, :logger, s(:arglist))
      def observe_call(sexp)
        super(sexp)
        return unless sexp[0] == :call
        target = sexp[1]
        method = sexp[2]
        params = sexp[3]
        if logger_target?(target) && log_method?(method) && spotty?(params) && !suppressed?(LogInformationLeak)
          scan.issues << LogInformationLeak.new(scan, self.file, sexp)
        end
      end

      protected

      def logger_target?(sexp)
        return false unless sexp && sexp[0] == :call
        method = sexp[2]
        !!(method && method.to_s =~ LOGGER_CALL_REGEXP)
      end

      def log_method?(method)
        !!(method.to_s =~ LOG_METHOD_CALL_REGEXP)
      end

      def spotty?(sexp)
        !!sexp && !sexp.constant?
      end

      def gather_includes(data)
        out = []
        case data
          when Array
            data.each { |elem| out += gather_includes(elem) }
          when Hash
            data.keys.each { |elem| out += gather_includes(elem) }
            data.values.each { |elem| out += gather_includes(elem) }
          when Symbol
            out << data
        end

        return out
      end
    end
  end
end