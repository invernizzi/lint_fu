module LintFu
  class Scan
    attr_reader :fs_root, :issues

    def initialize(fs_root)
      @fs_root = fs_root
      @issues = Set.new
    end
  end
end