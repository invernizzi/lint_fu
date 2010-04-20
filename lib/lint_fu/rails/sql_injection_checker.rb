module LintFu
  module Rails
    class SqlInjection < Issue
      def brief
        "SQL Injection"
      end

      def detail
        return <<-EOF
          A \#{dynamic string} is being used to interpolate Ruby code into a string expression.
          This may allow unfiltered user input to appear in ActiveRecord options like :conditions,
          :order, :join or :include, leading to SQL injection.
        EOF
      end

      def reference_info
        return <<-EOF
          A SQL injection vulnerability happens when input from the network is passed to ActiveRecord
          in a way that causes it to be interpreted as SQL. If a user can inject SQL into your app,
          he owns the database, game over.

          Preventing SQL injection involves using common sense. Don't do stuff that looks like this!

          <pre><code>
          Account.find(:conditions=>"name like '\#{params[:name]}'")
          Account.find(:conditions=>params[:query])
          </pre></code>
        EOF
      end
    end

    # Visit a Rails controller looking for ActiveRecord queries that contain interpolated
    # strings. 
    class SqlInjectionChecker < Checker
      FINDER_REGEXP  = /^(find|first|all)(_or_initialize)?(_by_.*_id)?/

      def initialize(scan, context, filename)
        super(scan, context, filename)
        @class_definition_scope = []
      end

      def observe_class_begin(sexp)
        @class_definition_scope.push sexp
      end

      def observe_class_end(sexp)
        @class_definition_scope.pop
      end

      def observe_defn_begin(sexp)
        
        @in_method = true
      end

      def observe_defn_end(sexp)
        @in_method = false
      end

      def observe_call(sexp)
        return if @class_definition_scope.empty? || !@in_method

        call    = sexp[2].to_s
        arglist = sexp[3]
        
        if finder?(call) && has_taint?(arglist)
          scan.issues << SqlInjection.new(scan, self.file, sexp)
        end
      end

      private

      def finder?(call)
        # We consider a method call to be a finder if it looks like an AR finder,
        # if it matches the name of ANY named scope, or it matches the name of
        # ANY association. This may create a false positive now and again, but
        # it's better than trying to puzzle out which class/association is being
        # called (until we have type inference and other cool stuff).
        ( call =~ FINDER_REGEXP ||
          analysis_model.models.detect { |m| m.named_scopes.has_key?(call) } ||
          analysis_model.models.detect { |m| m.associations.has_key?(call) })
      end

      def has_taint?(sexp)
        sexp.find_recursively { |se| se[0] == :dstr } ||
        sexp.find_recursively { |se| se[0] == :lvar && se[1] == :params }
      end
    end
  end
end