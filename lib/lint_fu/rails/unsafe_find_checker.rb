module LintFu
  module Rails
    class UnsafeFind < Issue
      def detail
        if @sexp[1] & @sexp[2]
          info = "#{@sexp[1].to_ruby_string}.#{@sexp[2].to_ruby_string}"
        else
          info = "an ActiveRecord finder"
        end

        "A controller is directly calling #{info}; the results may not be properly scoped or authorized."
      end
      
      def reference_info
        return <<-EOF
          An unsafe find happens when a controller makes an ActiveRecord query without performing
          an authorization check to determine whether the logged-in user is authorized to view
          and/or manipulate the resulting models.

          It is not trivial to determine whether a find is safe, because authorization can happen
          in many ways and the "right" way to do it depends on the application requirements. Here
          are some things to consider when evaluating whether a find is safe:
          * Do the find's conditions scope it in some way to current_user or current_account?
          * How will the results be used? What information is displayed in the view?
          * Are the results scoped afterward, e.g. by calling #select on the result set?
          * Is authorization checked afterward, e.g. by checking ownership and raising ActiveRecord::NotFound?
        EOF
      end
    end
    
    # Visit a Rails controller looking for troublesome stuff
    class UnsafeFindChecker < Checker
      FINDER_REGEXP  = /^(find|first|all)(_or_initialize)?(_by_.*_id)?/

      #sexp:: s(:class, <class_name>, <superclass>, s(:scope, <class_definition>))
      def observe_class_begin(sexp)
        @in_admin_controller = !!(sexp[1].to_ruby_string =~ /^Admin/)
      end

      #sexp:: s(:class, <class_name>, <superclass>, s(:scope, <class_definition>))
      def observe_class_end(sexp)
        @in_admin_controller = false
      end

      #sexp:: s(:call, <target>, <method_name>, s(:arglist))
      def observe_call(sexp)
        check_suspicious_finder(sexp)
      end

      protected

      def check_suspicious_finder(sexp)
        return if @in_admin_controller

        #sexp:: :call, <target>, <method_name>, <argslist...>
        if (sexp[1] != nil) && (sexp[1][0] == :const || sexp[1][0] == :colon2)
          name = sexp[1].to_ruby_string
          type = self.analysis_model.models.detect { |m| m.modeled_class_name == name }
          call = sexp[2].to_s

          if finder?(type, call) && !sexp[3].constant? && !sexp_contains_scope?(sexp[3]) && !blessed?(sexp, UnsafeFind)
            scan.issues << UnsafeFind.new(scan, self.file, sexp)
          end
        end        
      end

      def finder?(type, call)
        type.kind_of?(LintFu::ActiveRecord::ModelModel) &&
                     ( call =~ FINDER_REGEXP || type.associations.has_key?(call) )
      end

      def sexp_contains_scope?(sexp)
        return false if !sexp.kind_of?(Sexp) || sexp.empty?
        
        sexp_type = sexp[0]

        #If calling a method -- check to see if we're accessing a current_* method
        if (sexp_type == :call) && (sexp[1] == nil)
          return true if (sexp[2] == :current_user)
          return true if (sexp[2] == :current_account)
        end

        #Generic case: check all subexpressions of the sexp
        sexp.each do |subexp|
          if subexp.kind_of?(Sexp)
            return true if sexp_contains_scope?(subexp)            
          end
        end

        return false
      end
    end
  end
end