module LintFu
  module Rails
    class BuggyEagerLoad < Issue
      def detail
        "A find is attempting to eager-load an associated model that acts as paranoid. " +
        "THIS WILL CAUSE A BUG for :has_many associations when Rails falls back to JOIN " +
        "eager loading. Deleted models will return to life."
      end
    end
    
    # Visit a Rails controller looking for troublesome stuff
    class BuggyEagerLoadChecker < Checker
      FINDER_REGEXP  = /^(find|first|all)(_or_initialize)?(_by_.*)?/

      #sexp:: s(:call, <target>, <method_name>, s(:arglist))
      def observe_call(sexp)
        if finder?(sexp) && (spotty = spotty_includes(sexp[3])) && !blessed?(sexp, UnsafeFind)
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

        #if the finder's options hash is entirely constant, ba da bing
        return nil if sexp.size <= 1 || sexp.last.constant?

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