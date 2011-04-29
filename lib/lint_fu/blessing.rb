module LintFu
  class Blessing
    VERBOSE_BLESSING_COMMENT = /#\s*(lint|security)\s*[-:]\s*not\s*a?n?\s*([a-z0-9 ]*?) ?(as|because|;)\s*(.*)\s*/i
    BLESSING_COMMENT         = /#\s*(lint|security)\s*[-:]\s*not\s*a?n?\s*([a-z0-9 ]*?)\s*/i

    attr_accessor :issue_class, :sexp, :reason

    def initialize(issue_class, sexp=nil, reason=nil)
      @issue_class = issue_class
      @reason = reason
    end

    def applies_to?(klass)
      klass = klass.class unless klass.is_a?(Class)

      while klass
        return true if klass.name.index(self.issue_class)
        klass = klass.superclass
      end

      return false
    end

    def self.parse(comments, sexp=nil)
      comments = [comments] unless comments.kind_of?(Array)
      blessings = []

      comments.each do |line|
        match = VERBOSE_BLESSING_COMMENT.match(line)
        match = BLESSING_COMMENT.match(line) unless match
        next unless match
        issue_class = match[2].downcase.split(/\s+/).join('_').camelize
        reason      = match[3]
        blessings << Blessing.new(issue_class, sexp, reason)
      end

      return blessings
    end
  end
end