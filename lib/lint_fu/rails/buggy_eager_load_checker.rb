module LintFu
  module Rails
    class BuggyEagerLoad < Issue
      def detail
        "A find is attempting to eager-load an associated model that acts as paranoid. This may cause unexpected results."
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
        if finder?(sexp) && spotty_includes(sexp[3]) && !blessed?(sexp, UnsafeFind)
          scan.issues << BuggyEagerLoad.new(scan, self.file, sexp)
        end
      end

      protected

      def finder?(sexp)
        !!(sexp[2].to_s =~ FINDER_REGEXP)
      end

      def spotty_includes(sexp)
        arglist = ( sexp && (sexp[0] == :arglist) && sexp.to_ruby(:partial=>nil) )
        #no dice unless we're looking at an arglist
        return nil unless arglist

        #no eager loading? no problem!
        return nil unless arglist.last.is_a?(Hash) && arglist.last.has_key?(:include)
        
        gather_includes(arglist.last[:include]).each do |inc|
          plural     = inc.to_s
          singular   = plural.singularize
          class_name = singular.camelize
          type = self.analysis_model.models.detect { |m| m.modeled_class_name == class_name }
          # TODO replace this clever hack, which infers :has_many associations using plural/singular word comparison
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