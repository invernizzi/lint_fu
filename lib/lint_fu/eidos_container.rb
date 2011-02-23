module LintFu
  # An element of a static analysis model that contains, or consists of, eide. For instance,
  # an Application might consists of Models, Controllers and Views.
  module EidosContainer
    def eide
      return [].freeze unless @eide
      @eide.dup.freeze
    end

    def each_eidos(&block)
      @eide ||= Set.new()
      @eide.each(&block)
    end

    def add_eidos(sub)
      @eide ||= Set.new()
      @eide << sub
    end

    def remove_eidos(sub)
      @eide ||= Set.new()
      @eide.delete sub
    end
  end
end