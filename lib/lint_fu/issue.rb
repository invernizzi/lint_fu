module LintFu
  class Issue
    attr_reader :file, :sexp
    
    def initialize(scan, file, sexp)
      @scan = scan
      @file = file
      @sexp = sexp
    end

    def line
      @sexp.line
    end

    def relative_file()
      File.relative_path(@scan.fs_root, file)
    end

    def brief
      relative_path =
      "#{self.class.name.split('::')[-1].underscore.gsub('_', ' ').titleize} at #{relative_file}:#{line}"
    end

    def detail
      "There is an issue at #{file_basename}:#{line}."
    end

    def file_basename
      File.basename(file)
    end
  end
end