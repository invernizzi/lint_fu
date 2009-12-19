module LintFu
  class Visitor < SexpProcessor
    attr_reader :scan, :analysis_model, :file
    
    def initialize(scan, analysis_model, file=nil)
      super()
      self.require_empty   = false
      self.auto_shift_type = false
      @scan           = scan
      @analysis_model = analysis_model
      @file           = file
    end
  end
end