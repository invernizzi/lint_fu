module LintFu
  class ScanNotFinalized < Exception; end
  
  class Scan
    VERBOSE_BLESSING_COMMENT = /#\s*(lint|security)\s*[-:]\s*not\s*a?n?\s*([a-z0-9 ]*?) ?(as|because|;)\s*(.*)\s*/i
    BLESSING_COMMENT         = /#\s*(lint|security)\s*[-:]\s*not\s*a?n?\s*([a-z0-9 ]*?)\s*/i

    attr_reader :fs_root, :issues

    def initialize(fs_root)
      @fs_root = fs_root
      @issues = Set.new
    end

    def blessed?(issue)
      comments = issue.sexp.preceding_comments
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
  end
end
