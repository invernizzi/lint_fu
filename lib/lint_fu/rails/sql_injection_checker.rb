module LintFu
  module Rails
    class SqlInjection < Issue
      def brief
        "SQL Injection"
      end

      def detail
        return <<EOF
A \#{dynamic string} is being used to interpolate Ruby code into a string expression. This may allow unfiltered user input to appear in ActiveRecord options, leading to SQL injection.
EOF
      end

      def reference_info
        return <<EOF
h4. What is it?

A SQL injection vulnerability happens when input from an untrusted source is passed to ActiveRecord in a way that causes it to be interpreted as SQL. If users can inject SQL, they own your database, game over.

"Untrusted source" is usually the network but it could be a file on disk, or even a column in the database.

h4. When does it happen?

The most common source of SQL injection is request parameters that are used without properly escaping them.

bc. Account.first(:conditions=>"name like '\#{params[:name]}'")
User.all(:order=>params[:order_by])

h4. How do I fix it?

Instead of using query parameters directly, make a habit of _always_ using query parameter replacement:

bc. Account.first(:conditions=>[ 'name like ?', params[:name] ])

If you cannot use parameter replacement, escape the string manually using @ActiveRecord::Base#sanitize@.

bc. User.all(:order=>ActiveRecord::Base.sanitize(params[:order_by]))
EOF
      end
    end

    # Visit a Rails controller looking for ActiveRecord queries that contain interpolated
    # strings. 
    class SqlInjectionChecker < Checker
      FINDER_REGEXP = /^(find|first|all)(_or_initialize)?(_by_.*_id)?/
      SINK_OPTIONS  = Set.new([:conditions, :select, :order, :group, :from, :include, :join])
      
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
        
        if finder?(call) && has_tainted_params?(arglist)
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

      def has_tainted_params?(arglist)
        tainted_params = []

        #Find potentially-tainted members of the arglist's options hash(es)
        hash_params = arglist.find_all_recursively { |se| (Sexp === se) && (se[0] == :hash) }
        hash_params ||= []
        
        hash_params.each do |hash|
          hash = hash.clone
          hash.shift #get rid of the leading :hash marker

          #Iterate through the hash sexp, searching for keys whose values are known
          #to be vulnerable to taint.
          (0...hash.size).each do |n|
            next if n.odd?
            tainted_params << hash[n+1] if (hash[n][0] == :lit) && SINK_OPTIONS.include?(hash[n][1])
          end
        end

        #Find only those params whose values actually seem to be tainted
        tainted_params = tainted_params.select do |value|
          (Sexp === value) && value.find_recursively { |se| se[0] == :dstr }
        end

        return !tainted_params.empty?
      end      
    end
  end
end