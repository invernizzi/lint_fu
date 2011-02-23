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
end