module LintFu
  module Rails
    class DirectFinderCall < Issue
      def detail
        "A controller may be calling #{@sexp[1].to_ruby_string}.#{@sexp[2].to_ruby_string} " +
        "without scoping it to an account."
      end
    end
    
    # Visit a Rails controller looking for troublesome stuff
    class ControllerVisitor < Visitor
      FINDER_REGEXP = /^(find|first|all|find_by|first_by|all_by)/
      FIND_BY_REGEXP = /^(find(_or_initialize)_by_.*_id$)/

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

          if finder_call?(type, call) && !conditions_contain_scope?(type, call, sexp)
            i = DirectFinderCall.new(scan, self.file, sexp)
            scan.issues << i
          end
        end        
      end

      def finder_call?(type, call)
        type.kind_of?(LintFu::ActiveRecord::ModelModel) &&
                     ( call =~ FINDER_REGEXP || type.associations.has_key?(call) )
      end

      def conditions_contain_scope?(type, call, sexp)
        if !!(call =~ FIND_BY_REGEXP)
          #the first parameter should contain scope; search it
          return sexp_contains_scope?(sexp[3][1])
        else
          #the options hash should contain :conditions which points to scope; extract conditions & search them
          conditions = extract_conditions(sexp)
          return sexp_contains_scope?(conditions)
        end
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

      def extract_conditions(sexp, in_arglist=false)
        return nil if !sexp.kind_of?(Sexp) || (sexp.size < 2)
        
        sexp_type = sexp[0]
        remainder = sexp[1..-1]

        if sexp_type == :arglist
          #parse an argslist looking for a conditions hash
          return extract_conditions(remainder, true)
        elsif sexp_type == :hash && in_arglist
          #scan each member of the hash for :conditions=>blah_with_current_thingie
          #return the value of :conditions as a sexp
          while !remainder.empty?
            key = remainder.shift
            value = remainder.shift
            if key == s(:lit, :conditions)
              return value
            end
          end
        else
          remainder.each do |subexp|
            res = extract_conditions(subexp, in_arglist)
            return res if res
          end
          return nil
        end
      end
    end
  end
end