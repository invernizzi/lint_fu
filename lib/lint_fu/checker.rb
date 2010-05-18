module LintFu
  class Checker
    attr_reader :scan, :analysis_model, :file

    def initialize(scan, analysis_model, file=nil)
      @scan           = scan
      @analysis_model = analysis_model
      @file           = file
    end
  end
end