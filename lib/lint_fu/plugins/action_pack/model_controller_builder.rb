module LintFu::Plugins
  module ActionPack
    class ModelControllerBuilder < LintFu::EidosFactory
      SIGNATURE_SEXP = s(:colon2, s(:const, :ActionController), :Base)

      #sexp:: [:class, <classname>, <superclass|nil>, <CLASS DEFS>]
      def process_class(sexp)
        return super(sexp) unless sexp[2] && sexp[2] == SIGNATURE_SEXP
        
        unless self.current_model_element
          self.current_model_element = ModelController.new(sexp, self.namespace)
          did_element = true
        end

        ret = super(sexp)

        if did_element
          self.eide.push self.current_model_element
          self.current_model_element = nil
        end

        return ret
      end
    end
  end
end