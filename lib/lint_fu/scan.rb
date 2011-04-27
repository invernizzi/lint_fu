module LintFu
  class ScanNotFinalized < Exception; end
  
  class Scan
    attr_reader :fs_root, :issues

    def initialize(fs_root)
      @fs_root = fs_root
      @issues = Set.new
    end

    def blessed?(issue)
      issue.sexp.blessings.any? { |b| b.issue_class = issue.class }
    end
  end
end
