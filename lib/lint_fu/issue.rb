module LintFu
  class Issue
    attr_reader :file, :sexp, :confidence
    
    def initialize(scan, file, sexp, confidence=1.0)
      @scan = scan
      @file = file
      @sexp = sexp.deep_clone
      self.confidence = confidence
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

    def issue_hash()
      Digest::SHA1.hexdigest("#{self.class.name} - #{self.relative_file} - #{sexp.fingerprint}")
    end

    def confidence=(confidence)
      raise ArgumentError, "Confidence must be a real number in the range (0..1)" unless (0..1).include?(confidence)
      @confidence = confidence
    end
  end
end