module LintFu
  class Visitor < SexpProcessor
    TERSE_BLESSING_COMMENT   = /^\s*#\s*security\s*[:\-]\s*not\s+a?n? ?(.*)$/i
    VERBOSE_BLESSING_COMMENT = /^\s*#\s*security\s*[:\-]\s*not\s+a?n? ?(.*)\s+because\s+(.*)$/i
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
      return false unless comments
      match = VERBOSE_BLESSING_COMMENT.match(comments)
      match = TERSE_BLESSING_COMMENT.match(comments) unless match
      return false unless match
      blessed_issue_class = match[1].downcase.split(/\s+/).join('_').camelize

      #Ascend the class hierarchy of the issue that was found looking for type names
      #similar to the type that was blessed in the comment.
      klass = issue_class
      while klass
        return true if klass.name.index(blessed_issue_class)
        klass = klass.superclass
      end

      return false
    end

    def preceeding_comments(sexp)
      @file_contents ||= File.readlines(self.file)
      line = @file_contents[sexp.line - 1 - 1];
      return line if line =~ /^\s*#/
    end
  end
end