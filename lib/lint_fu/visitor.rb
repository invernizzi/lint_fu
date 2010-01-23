module LintFu
  class Visitor < SexpProcessor
    COMMENT                  = /^\s*#/
    VERBOSE_BLESSING_COMMENT = /#\s*security\s*[-:]\s*not\s*a?n?\s*(.*) because (.*)/i
    BLESSING_COMMENT         = /#\s*security\s*[-:]\s*not\s*a?n?\s*(.*)/i

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

      match = nil
      comments.each do |line|
        match = VERBOSE_BLESSING_COMMENT.match(line)
        match = BLESSING_COMMENT.match(line) unless match
        break if match
      end

      return false unless match
      blessed_issue_class = match[1].downcase.split(/\s+/).join('_').camelize

      # Determine whether the blessed issue class appears anywhere in the class hierarchy of
      # issue_class.
      klass = issue_class
      while klass
        return true if klass.name.index(blessed_issue_class)
        klass = klass.superclass
      end

      return false
    end

    def preceeding_comments(sexp)
      @file_contents ||= File.readlines(self.file)

      comments = ''

      max_line = sexp.line - 1 - 1
      max_line = 0 if max_line < 0
      min_line = max_line

      while @file_contents[min_line] =~ COMMENT && min_line >= 0
        min_line -= 1
      end

      if @file_contents[max_line] =~ COMMENT
        min_line +=1 unless min_line == max_line
        return @file_contents[min_line..max_line]
      else
        return nil
      end
    end
  end
end