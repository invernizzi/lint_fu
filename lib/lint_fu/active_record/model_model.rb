module LintFu
  module ActiveRecord
    class ModelModel < ModelElement
      attr_reader :associations
      attr_writer :paranoid
      
      def initialize(sexp, namespace=nil)
        super(sexp, namespace)
        @associations = {}
      end

      def paranoid?
        !!@paranoid
      end
    end
  end
end