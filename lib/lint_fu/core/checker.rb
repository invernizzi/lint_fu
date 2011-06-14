module LintFu::Core
  class Checker
    SUPPRESSION_COMMENT = /#\s*lint\s*[-:]\s*(suppress|ignore) (.*)/i

    attr_reader :scan, :context, :file

    def initialize(scan, context, file=nil)
      @scan       = scan
      @context    = context
      @file       = file
      @suppressed = []
    end

    # This class responds to any method beginning with "observe_" in order to provide
    # a default callback for every kind of Sexp it might encounter.
    def method_missing(meth, *args)
      return true if meth.to_s =~ /^observe_/
      super(meth, *args)
    end

    def observe_class_begin(sexp)
      enter_suppression_scope(sexp)
    end

    def observe_class_end(sexp)
      leave_suppression_scope(sexp)
    end

    protected

    def suppressed?(klass)
      basename = klass.name.split('::').last
      @suppressed.any? { |s| s.include?(basename) }
    end

    private

    def enter_suppression_scope(sexp)
      set = Set.new

      if (comments = sexp.preceding_comments)
        comments.each do |line|
          match = SUPPRESSION_COMMENT.match(line)
          next unless match
          list = match[2].split(/\s*(,|and)\s*/)
          list.each { |s| set << s.gsub(/\s+/, '_').camelize }
        end
      end

      @suppressed.push set
    end

    def leave_suppression_scope(sexp)
      @suppressed.pop      
    end
  end
end