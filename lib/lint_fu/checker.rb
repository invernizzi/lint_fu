module LintFu
  class Checker
    attr_reader :scan, :context, :file

    def initialize(scan, context, file=nil)
      @scan           = scan
      @context = context
      @file           = file
    end
  end
end