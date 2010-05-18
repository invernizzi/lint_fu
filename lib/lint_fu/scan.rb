module LintFu
  class ScanNotFinalized < Exception; end
  
  class Scan
    COMMENT                  = /^\s*#/
    VERBOSE_BLESSING_COMMENT = /#\s*(lint|security)\s*[-:]\s*not\s*a?n?\s*([a-z0-9 ]*) ?(because|;)\s*(.*)/i
    BLESSING_COMMENT         = /#\s*(lint|security)\s*[-:]\s*not\s*a?n?\s*([a-z0-9 ]*)/i

    attr_reader :fs_root, :genuine_issues

    def initialize(fs_root)
      @fs_root = fs_root
      @issues = Set.new
      @genuine_issues = Set.new
    end

    def add_issue(issue)
      @issues << issue
      @genuine_issues << issue unless blessed?(issue)
    end

    protected

    def blessed?(issue)
      comments = preceeding_comments(issue.sexp)
      return false unless comments

      match = nil
      comments.each do |line|
        match = VERBOSE_BLESSING_COMMENT.match(line)
        match = BLESSING_COMMENT.match(line) unless match
        break if match
      end

      return false unless match
      blessed_issue_class = match[2].downcase.split(/\s+/).join('_').camelize

      # Determine whether the blessed issue class appears anywhere in the class hierarchy of
      # issue_class.
      klass = issue.class
      while klass
        return true if klass.name.index(blessed_issue_class)
        klass = klass.superclass
      end

      return false
    end

    def preceeding_comments(sexp)
      @file_contents ||= {}
      @file_contents[sexp.file] ||= File.readlines(sexp.file)
      cont = @file_contents[sexp.file]

      comments = ''

      max_line = sexp.line - 1 - 1
      max_line = 0 if max_line < 0
      min_line = max_line

      while cont[min_line] =~ COMMENT && min_line >= 0
        min_line -= 1
      end

      if cont[max_line] =~ COMMENT
        min_line +=1 unless min_line == max_line
        return cont[min_line..max_line]
      else
        return nil
      end
    end    
  end
end