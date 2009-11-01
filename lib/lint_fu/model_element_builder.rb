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

    def process_module(sexp)
      @namespace.push s[1]
      process(s[2])
      @namespace.pop
      return sexp
    end

    def process_class(sexp)
      @namespace.push s[1]
      process(s[2])
      @namespace.pop
      return sexp
    end
  end
end