module LintFu
  module Mixins
    module SymbolInstanceMethods
      def to_ruby_string
        self.to_s
      end
    end
  end
end

Symbol.instance_eval do
  include LintFu::Mixins::SymbolInstanceMethods
end