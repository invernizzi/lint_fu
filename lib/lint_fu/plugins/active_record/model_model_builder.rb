module LintFu::Plugins
  module ActiveRecord
    class ModelModelBuilder < LintFu::EidosFactory
      SIGNATURE_SEXP = s(:colon2, s(:const, :ActiveRecord), :Base)      

      SINGULAR_ASSOCS = Set.new([:belongs_to, :has_one])
      PLURAL_ASSOCS   = Set.new([:has_many, :has_and_belongs_to_many])
      ASSOCS          = SINGULAR_ASSOCS + PLURAL_ASSOCS

      #sexp:: [:class, <classname>, <superclass|nil>, <CLASS DEFS>]
      def process_class(sexp)
        return super(sexp) unless sexp[2] && sexp[2] == SIGNATURE_SEXP

        unless self.current_model_element
          self.current_model_element = ModelModel.new(sexp, self.namespace)
          did_element = true
        end

        ret = super(sexp)

        if did_element
          self.eide.push self.current_model_element
          self.current_model_element = nil
        end

        return ret
      end

      #s(:call, nil, :belongs_to, s(:arglist, s(:lit, :relation_name)))
      def process_call(sexp)
        return sexp unless self.current_model_element

        callee, method, arglist = sexp[1], sexp[2], sexp[3]
        arglist = nil unless arglist[0] == :arglist
        discover_associations(callee, method, arglist)
        discover_named_scopes(callee, method, arglist)
        discover_paranoia(callee, method, arglist)
        return sexp
      end

      private
      def discover_associations(callee, method, arglist)
        #Is the call declaring an ActiveRecord association?
        if (callee == nil) && ASSOCS.include?(method) && arglist
          assoc_name = arglist[1].to_ruby

          # TODO grok :class_name option
          if SINGULAR_ASSOCS.include?(method)
            assoc_class_name = assoc_name.to_s.camelize
          else
            assoc_class_name = assoc_name.to_s.singularize.camelize
          end

          self.current_model_element.associations[assoc_name] = assoc_class_name
        end        
      end

      def discover_named_scopes(callee, method, arglist)
        #Is the call declaring a named scope?
        if (callee == nil && method == :named_scope) && arglist
          scope_name = arglist[1].to_ruby
          scope_args = arglist[2..-1].to_ruby(:partial=>nil)
          self.current_model_element.named_scopes[scope_name] = scope_args
        end
      end

      def discover_paranoia(callee, method, arglist)
        self.current_model_element.paranoid = true if (method == :acts_as_paranoid)
      end
    end
  end
end