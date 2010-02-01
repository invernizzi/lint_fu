module LintFu
  module ActiveRecord
    class ModelModelBuilder < ModelElementBuilder
      SINGULAR_ASSOCS = Set.new([:belongs_to, :has_one])
      PLURAL_ASSOCS   = Set.new([:has_many, :has_and_belongs_to_many])
      ASSOCS          = SINGULAR_ASSOCS + PLURAL_ASSOCS

      #sexp:: [:class, <classname>, <superclass|nil>, <CLASS DEFS>]
      def process_class(sexp)
        unless @current_model_element
          @current_model_element = ModelModel.new(sexp, self.namespace)
          did_element = true
        end

        ret = super(sexp)

        if did_element
          self.model_elements.push @current_model_element
          @current_model_element = nil
        end

        return ret
      end

      #s(:call, nil, :belongs_to, s(:arglist, s(:lit, :relation_name)))
      def process_call(sexp)
        callee, method, arglist = sexp[1], sexp[2], sexp[3]
        arglist = nil unless arglist[0] == :arglist
        discover_associations(callee, method, arglist)
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

          @current_model_element.associations[assoc_name] = assoc_class_name
        end        
      end

      def discover_paranoia(callee, method, arglist)
        @current_model_element.paranoid = true if (method == :acts_as_paranoid)
      end
    end
  end
end