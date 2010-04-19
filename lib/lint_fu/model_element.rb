module LintFu
  # An element of a static analysis model that contains, or consists of, submodels. For instance,
  # an Application might consists of Models, Controllers and Views.
  module SuperModel
    def submodels
      return [].freeze unless @submodels
      @submodels.dup.freeze
    end

    def each_submodel(&block)
      @submodels ||= Set.new()
      @submodels.each(&block)
    end

    def add_submodel(sub)
      @submodels ||= Set.new()
      @submodels << sub
    end

    def remove_submodel(sub)
      @submodels ||= Set.new()
      @submodels.delete sub
    end
  end

  # An element of the static analysis model being created; generally corresponds to a
  # class (e.g. model, controller or view) within the application being scanned.
  module ModelElement
    attr_accessor :supermodel
    attr_reader   :modeled_class_name, :modeled_class_superclass_name, :parse_tree

    #sexp:: [:class, <classname>, <superclass|nil>, <CLASS DEFS>]
    #namespace:: Array of enclosing module names for this class 
    def initialize(sexp, namespace=nil)
      @parse_tree = sexp
      if namespace
        @modeled_class_name = namespace.join('::') + (namespace.empty? ? '' : '::') + sexp[1].to_s
      else
        @modeled_class_name = sexp[1]
      end
    end

    #Have a pretty string representation
    def to_s
      "<<model of #{modeled_class_name}>>"
    end
  end
end