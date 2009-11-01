module LintFu
  module ActiveRecord
    class Model < ModelElement
      attr_reader :associations

      def initialize(sexp, namespace=nil)
        super(sexp, namespace)
        @associations = {}        
      end
    end

    class ModelBuilder < ModelElementBuilder
      SINGULAR_ASSOCS = Set.new([:belongs_to, :has_one])
      PLURAL_ASSOCS   = Set.new([:has_many, :has_and_belongs_to_many])
      ASSOCS          = SINGULAR_ASSOCS + PLURAL_ASSOCS

      #sexp:: [:class, <classname>, <superclass|nil>, <CLASS DEFS>]
      def process_class(sexp)
        unless @current_model_element
          @current_model_element = Model.new(sexp, self.namespace)
          did_element = true
        end

        process(sexp[3])

        if did_element
          self.model_elements.push @current_model_element
          @current_model_element = nil
        end

        return sexp
      end

      #s(:call, nil, :belongs_to, s(:arglist, s(:lit, :relation_name)))
      def process_call(sexp)
        callee, meth, arglist = sexp[1], sexp[2], sexp[3]

        #Is the call declaring an ActiveRecord association?
        if (callee == nil) && ASSOCS.include?(meth) && arglist && (arglist[0] == :arglist)
          assoc_name = sexp[3][1].to_ruby

          # TODO grok :class_name option
          if SINGULAR_ASSOCS.include?(meth)
            assoc_class_name = assoc_name.to_s.camelize
          else
            assoc_class_name = assoc_name.to_s.singularize.camelize
          end

          @current_model_element.associations[assoc_name] = assoc_class_name
        end

        return sexp
      end
    end
  end
end