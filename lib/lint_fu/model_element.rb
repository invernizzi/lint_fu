module LintFu
  # An element of the application model that consists in part of submodels 
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

  # An element of the application model being scanned; generally a class.
  class ModelElement
    attr_reader :supermodel, :modeled_class_name, :modeled_class_superclass_name, :parse_tree

    # DSL command to mark a ModelElement as a container for other ModelElements
    def self.acts_as_supermodel
      include SuperModel
    end

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

    attr_accessor :supermodel
    
    #Have a pretty string representation
    def to_s
      "<<model of #{modeled_class_name}>>"
    end
  end
end