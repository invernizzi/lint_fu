module LintFu
  module Rails
    class DirectFinderCall < Issue
      def detail
        "A controller is calling #{@sexp[1].to_ruby_string}.#{@sexp[2]} " +
        "without scoping it to a particular context. If users are allowed to influence " +
        "the finder's conditions, this may allow attackers to obtain information that " +
        "does not belong to them."
      end
    end
    
    # Visit a Rails controller looking for troublesome stuff
    class ControllerVisitor < Visitor
      FINDER_REGEXP = /^(find|first|all|find_by|first_by|all_by)/
      
      #sexp:: s(:call, <target>, <method_name>, s(:arglist))
      def process_call(sexp)
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

        return sexp
      end
    end
  end
end