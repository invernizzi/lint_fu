module LintFu::Plugins
  module Rails
    class UnsafeFind < LintFu::Issue
      def initialize(scan, file, sexp, subject)
        super(scan, file, sexp)
        @subject = subject
      end


      def detail
        return "Could a bad guy manipulate <code>#{@subject}</code> and get/change stuff he shouldn't?"
      end
      
      def reference_info
        return <<EOF
h4. What is it?

An unsafe find is an ActiveRecord query that is performed without checking whether the logged-in user is authorized to view or manipulate the resulting models.

h4. When does it happen?

Some trivial examples:

bc. BankAccount.first(params[:id]).destroy
Account.all(:conditions=>{:nickname=>params[:nickname]})

In reality, it is often hard to determine whether a find is safe. Authorization can happen in many ways and the "right" way to do it depends on the application requirements.

Here are some things to consider when evaluating whether a find is safe:

* Is authorization checked beforehand or afterward, e.g. by checking ownership of the model?
* Do the query's conditions scope it in some way to the current user or account?
* How will the results be used? What information is displayed in the view?
* Are the results scoped afterward, e.g. by calling @select@ on the result set?

h4. How do I fix it?

Use named scopes to scope your queries instead of calling the class-level finders:

bc. current_user.bank_accounts.first(params[:id])

If a named scope is not convenient, include conditions that scope the query:

bc. BankAccount.find(:conditions=>{:owner_id=>current_user})

If your authorization rules are so complex that neither of those approaches work, always make sure to perform authorization yourself:

bc. #My bank allows customers to access ANY account on their birthday
@bank_account = BankAccount.first(params[:id])
raise ActiveRecord::RecordNotFound unless current_user.born_on = Date.today
EOF
      end
    end
    
    # Visit a Rails controller looking for ActiveRecord finders being called in a way that
    # might allow an attacker to perform unauthorized operations on resources, e.g. creating,
    # updating or deleting someone else's records.
    class UnsafeFindChecker < LintFu::Checker
      FINDER_REGEXP  = /^(find|first|all)(_or_initialize)?(_by_.*_id)?/
      #TODO: make this tunable, also expose it to the user to make sure it's appropriate!!
      SAFE_INSTANCE_METHODS = [:current_user, :current_account]

      #sexp:: s(:call, <target>, <method_name>, s(:arglist))
      def observe_call(sexp)
        super(sexp)
        check_suspicious_finder(sexp)
      end

      protected

      def check_suspicious_finder(sexp)
        #sexp:: :call, <target>, <method_name>, <argslist...>
        if (sexp[1] != nil) && (sexp[1][0] == :const || sexp[1][0] == :colon2)
          name = sexp[1].to_ruby_string
          type = self.context.models.detect { |m| m.modeled_class_name == name }
          call   = sexp[2].to_s
          params = sexp[3]
          if finder?(type, call) && !params.constant? &&
             !safely_scoped?(params) && !suppressed?(UnsafeFind)
            scan.issues << UnsafeFind.new(scan, self.file, sexp, params.to_ruby_string)
          end
        end        
      end

      def finder?(type, call)
        type.kind_of?(LintFu::Plugins::ActiveRecord::ModelEidos) &&
                     ( call =~ FINDER_REGEXP || type.associations.has_key?(call) )
      end

      def safely_scoped?(sexp)
        return false if !sexp.kind_of?(Sexp) || sexp.empty?
        return true if sexp.constant?
        
        #Some local methods introduce safe scope
        if (sexp[0] == :call)
          #TODO get rid of RightScale-specific assumptions
          return true if sexp[1].nil? && SAFE_INSTANCE_METHODS.include?(sexp[2])
        end

        #Generic case: check all subexpressions of the sexp
        sexp.each do |subexp|
          if subexp.kind_of?(Sexp)
            return true if safely_scoped?(subexp)
          end
        end

        return false
      end
    end
  end
end