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

    def relative_file
      File.relative_path(@scan.fs_root, file)
    end

    def brief
      self.class.name.split('::')[-1].underscore.gsub('_', ' ').titleize
    end

    def detail
      "There is an issue at #{file_basename}:#{line}."
    end

    def reference_info
      "No reference information is available for #{brief}."
    end

    def file_basename
      File.basename(file)
    end

    def hash()
      Digest::SHA1.hexdigest("#{self.class.name} - #{self.relative_file} - #{sexp.line} - #{sexp.to_s}")
    end
  end
end