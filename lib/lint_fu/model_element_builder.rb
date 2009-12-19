module LintFu
  class ModelElementBuilder < SexpProcessor
    attr_reader :model_elements, :namespace
    
    def initialize(namespace=nil)
      super()
      @model_elements = []
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
  end
end