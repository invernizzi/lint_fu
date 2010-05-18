module LintFu
  module Rails
    class BuggyEagerLoad < Issue
      def initialize(scan, file, sexp, subject)
        super(scan, file, sexp)
        @subject = subject
      end

      def detail
        "Instances of the paranoid model <code>#{@subject}</code> are being eager-loaded. This may cause unexpected results."
      end

      def reference_info
        return <<EOF
h4. What is it?

A buggy eager load happens when an ActiveRecord finder performs eager loading of a @:has_many@ association and the "target" of the association acts as paranoid.

The acts_as_paranoid plugin does not correctly eager loads that use a @JOIN@ strategy. If a paranoid model is eager loaded in this way, _all_ models -- even deleted ones -- will be loaded.

h4. When does it happen?

A finder with any of the following properties will cause Rails to eager-load using @JOIN@

* complex @:conditions@ option (containing SQL fragments, or referring to tables using strings)
* complex @:order@
* complex @:join@
* complex @:include@
* use of named scopes (which almost always add complex options to the query)

If your find exhibits any of these properties and it @:include@s a paranoid model, then you have a problem.

h4. How do I fix it?

Avoid doing complex finds at the same time you @:include@ a paranoid model.

EOF
      end
    end
    
    # Visit a Rails controller looking for troublesome stuff
    class BuggyEagerLoadChecker < Checker
      FINDER_REGEXP  = /^(find|first|all)(_or_initialize)?(_by_.*)?/

      #sexp:: s(:call, <target>, <method_name>, s(:arglist))
      def observe_call(sexp)
        return unless finder?(sexp)
        if finder?(sexp) && (si = spotty_includes(sexp[3]))
          scan.issues << BuggyEagerLoad.new(scan, self.file, sexp, si.modeled_class_name)
        end
      end

      protected

      def finder?(sexp)
        !!(sexp[2].to_s =~ FINDER_REGEXP)
      end

      def spotty_includes(sexp)
        #transform the sexp (if it's an arglist) into a hash for easier scrutiny
        arglist = ( sexp && (sexp[0] == :arglist) && sexp.to_ruby(:partial=>nil) )
        #no dice unless we're looking at an arglist
        return nil unless arglist

        #no options hash in arglist? no problem!
        return nil unless (options = arglist.last).is_a?(Hash)

        does_eager_loading = options.has_key?(:include)
        has_complexity_prone_params =
                options.has_key?(:conditions) ||
                options.has_key?(:order) ||
                options.has_key?(:joins) || 
                options.has_key?(:group)

        #no eager loading, or no complexity-prone params? no problem!
        return nil unless does_eager_loading && has_complexity_prone_params
        
        gather_includes(arglist.last[:include]).each do |inc|
          plural     = inc.to_s
          singular   = plural.singularize
          class_name = singular.camelize
          type = self.analysis_model.models.detect { |m| m.modeled_class_name == class_name }
          # If we're eager loading a 1:1 association, don't bother to scream; it's likely
          # that use the user would want to load the deleted thing anyway.
          # TODO replace this clever hack, which infers a :has_many association using plurality
          if !type || ( type.paranoid? && (plural != singular) )
            return type
          end
        end

        return nil
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