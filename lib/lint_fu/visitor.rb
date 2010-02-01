module LintFu
  class GenericVisitor < SexpProcessor
    attr_reader :observers
    
    def initialize
      super
      self.require_empty   = false
      self.auto_shift_type = false
      @observers      = []
    end

    def process(sexp)
      tag = sexp[0]

      begin_meth  = "observe_#{tag}_begin".to_sym
      around_meth = "observe_#{tag}".to_sym
      end_meth    = "observe_#{tag}_end".to_sym

      observers.each do |o|
        o.__send__(begin_meth, sexp) if o.respond_to?(begin_meth)
      end

      observers.each do |o|
        o.__send__(around_meth, sexp) if o.respond_to?(around_meth)
      end

      result = super(sexp)

      observers.each do |o|
        o.__send__(end_meth, sexp) if o.respond_to?(end_meth)
      end

      return result
    end
  end
end
