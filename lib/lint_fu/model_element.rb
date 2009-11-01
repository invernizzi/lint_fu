module LintFu
  class ModelElement
    attr_reader :supermodel, :modeled_class_name, :modeled_class_superclass_name, :parse_tree

    def self.acts_as_supermodel
      def submodels
        @submodels ||= Set.new()
      end
    end

    #sexp:: [:class, <classname>, <superclass|nil>, <CLASS DEFS>]
    #namespace:: Array of enclosing module names for this class 
    def initialize(sexp, namespace=nil)
      @parse_tree = sexp
      if namespace
        @modeled_class_name = namespace.join('::') + '::' + sexp[1].to_s
      else
        @modeled_class_name = sexp[1]
      end
    end

    #Have a pretty string representation
    def to_s
      "<<model of #{modeled_class_name}>>"
    end

    # Allow easy declaration and query of predicates (facts) about models.
    # This allows model elements to treat any method call ending in ? (or !)
    # as a predicate query (or declaration).
    def method_missing(meth, *args)
      @predicates ||= Hash.new(false)

      meth = meth.to_s
      if meth =~ /\?$/
        @predicates[ meth[0...-1] ]
      elsif meth =~ /!$/
        @predicates[ meth[0...-1] ] = true
      else
        super(meth, *args)
      end
    end
  end
end