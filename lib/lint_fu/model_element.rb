module LintFu
  # An element of the static analysis model being created; generally corresponds to a
  # class (e.g. model, controller or view) within the application being scanned.
  module ModelElement
    attr_accessor :supermodel
    attr_reader   :modeled_class_name, :modeled_class_superclass_name, :parse_tree

    VALID_SEXPS         = Set.new([:class, :module])

    #sexp:: [:class, <classname>, <superclass|nil>, <CLASS DEFS>]
    #namespace:: Array of enclosing module names for this class 
    def initialize(sexp, namespace=nil)
      unless VALID_SEXPS.include?(sexp[0])
        raise ArgumentError, "Must be constructed from a class-definition Sexp"
      end

      @sexp = sexp
      if namespace
        @modeled_class_name = namespace.join('::') + (namespace.empty? ? '' : '::') + sexp[1].to_s
      else
        @modeled_class_name = sexp[1]
      end
    end

    #Have a pretty string representation
    def to_s
      "<<model of #{self.modeled_class_name}>>"
    end
  end
end