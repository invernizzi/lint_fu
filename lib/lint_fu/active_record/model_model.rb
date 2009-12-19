module LintFu
  module ActiveRecord
    class ModelModel < ModelElement
      attr_reader :associations

      def initialize(sexp, namespace=nil)
        super(sexp, namespace)
        @associations = {}        
      end
    end
  end
end