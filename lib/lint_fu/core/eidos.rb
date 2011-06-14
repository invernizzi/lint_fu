module LintFu::Core
  # An eidos (plural: eide) holds information about a Ruby class, module or other
  # relevant piece of code. The name comes from Plato's theory of forms; the
  # eidos is the universal abstraction of an entire class of objects.
  #
  # Eide are built during the first pass of static analysis by parsing all source
  # files in the project. On the second pass, the checkers parse selected bits of
  # code, using the eide to better understand the code they are parsing. 
  module Eidos
    attr_accessor :parent_eidos
    attr_reader   :modeled_class_name, :modeled_class_superclass_name, :parse_tree

    VALID_SEXPS = Set.new([:class, :module])

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