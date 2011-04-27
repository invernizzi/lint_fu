module LintFu
  class EidosBuilder < SexpProcessor
    attr_reader   :namespace, :eide
    attr_accessor :current_model_element
    
    def initialize(namespace=nil)
      super()
      @eide = []
      @namespace = namespace || []
      self.require_empty   = false
      self.auto_shift_type = false      
    end

    #sexp:: [:module, <modulename>, <:scope - MODULE DEFS>]
    def process_module(sexp)
      @namespace.push sexp[1]
      process(sexp[2])
      @namespace.pop
      return sexp
    end

    #sexp:: [:class, <classname>, <superclass|nil>, <:scope - CLASS DEFS>]
    def process_class(sexp)
      @namespace.push sexp[1]
      process(sexp[3])
      @namespace.pop
      return sexp
    end

    def build
      raise NotImplemented      
    end
  end
end