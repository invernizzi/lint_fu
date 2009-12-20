module LintFu
  module Rails
    class DirectFinderCall < Issue
      def detail
        "A controller is calling #{@sexp[1].to_ruby_string}.#{@sexp[2].to_ruby_string} " +
        "without scoping it to an account."
      end
    end
    
    # Visit a Rails controller looking for troublesome stuff
    class ControllerVisitor < Visitor
      FINDER_REGEXP = /^(find|first|all|find_by|first_by|all_by)/

      #sexp:: s(:class, <class_name>, <superclass>, s(:scope, <class_definition>))
      def process_class(sexp)
        @in_admin_controller = !!(sexp[1].to_ruby_string =~ /^Admin/)
        process(sexp[3])
        @in_admin_controller = false
        return sexp
      end

      #sexp:: s(:call, <target>, <method_name>, s(:arglist))
      def process_call(sexp)
        check_suspicious_finder(sexp)
        process(s[3])
        return sexp
      end

      protected

      def check_suspicious_finder(sexp)
        return if @in_admin_controller
        
        if (sexp[1] != nil) && (sexp[1][0] == :const || sexp[1][0] == :colon2)
          name = sexp[1].to_ruby_string
          type = self.analysis_model.models.detect { |m| m.modeled_class_name == name }
          call = sexp[2].to_s

          if type.kind_of?(LintFu::ActiveRecord::ModelModel) &&
             ( call =~ FINDER_REGEXP || type.associations.has_key?(call) )
            i = DirectFinderCall.new(scan, self.file, sexp)
            scan.issues << i
          end
        end        
      end
    end
  end
end