module LintFu
  module Rails
    class BuggyEagerLoad < Issue
      def detail
        "A find is attempting to eager-load an associated model that acts as paranoid. " +
        "When Rails uses a join strategy to eager-load, a bug in the plugin will cause ALL " +
        "associated models to load, even deleted ones!"
      end
    end
    
    # Visit a Rails controller looking for troublesome stuff
    class BuggyEagerLoadChecker < Checker
      FINDER_REGEXP  = /^(find|first|all)(_or_initialize)?(_by_.*)?/

      #sexp:: s(:call, <target>, <method_name>, s(:arglist))
      def observe_call(sexp)
        if finder?(sexp) && (spotty = spotty_includes(sexp)) && !blessed?(sexp, UnsafeFind)
          scan.issues << BuggyEagerLoad.new(scan, self.file, sexp)
        end
      end

      protected

      def finder?(sexp)
        sexp[2] =~ FINDER_REGEXP
      end

      def spotty_includes(sexp)
        arglist = s[3] && s[3].to_ruby
        return nil unless arglist
        return nil unless arglist.last.is_a?(Hash) && arglist.last.has_key?(:include)
        gather_includes(arglist.last[:include]).each do |include|
          type = self.analysis_model.models.detect { |m| m.modeled_class_name == name }
          if type && type.paranoid?
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