module LintFu
  class Visitor < SexpProcessor
    BLESSING_COMMENT = /^\s*#\s*security\s*[:\-]\s*not a?n? ?(.*)/i
    attr_reader :scan, :analysis_model, :file
    
    def initialize(scan, analysis_model, file=nil)
      super()
      self.require_empty   = false
      self.auto_shift_type = false
      @scan           = scan
      @analysis_model = analysis_model
      @file           = file
    end

    protected

    def blessed?(sexp, issue_class)
      comments = preceeding_comments(sexp)
      puts sexp
      puts "------------"
      puts comments
      puts !!(BLESSING_COMMENT.match(comments))
      puts "------------"
      puts

      return false unless comments
      match = BLESSING_COMMENT.match(comments)
      return false unless match
      blessed_issue_class = match[1].downcase.split(/\s+/).join('_').camelize
      return false unless issue_class.name.index(blessed_issue_class)
      return true
    end

    def preceeding_comments(sexp)
      @file_contents ||= File.readlines(self.file)
      line = @file_contents[sexp.line - 1 - 1];
      return line if line =~ /^\s*#/
    end
  end
end