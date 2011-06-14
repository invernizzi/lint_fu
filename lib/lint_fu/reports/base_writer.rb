module LintFu::Reports
  class BaseWriter
    attr_reader :scan, :scm

    def initialize(scan, scm, included_issues)
      @scan   = scan
      @scm    = scm
      @issues = included_issues
    end

    def generate(output_stream)
      raise NotImplementedError, "Subclass responsibility"
    end
  end
end