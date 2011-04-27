module LintFu::Plugins
  module ActiveRecord
    class ModelEidos
      include LintFu::Eidos
      
      attr_reader :associations
      attr_reader :named_scopes
      attr_writer :paranoid
      
      def initialize(sexp, namespace=nil)
        super(sexp, namespace)
        @associations = {}
        @named_scopes = {}
      end

      def paranoid?
        !!@paranoid
      end
    end
  end
end