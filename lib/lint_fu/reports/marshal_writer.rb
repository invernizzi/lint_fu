module LintFu::Reports
  class MarshalWriter < BaseWriter
    def generate(output_stream)
      output_stream.write(Marshal.dump(@scan))
    end
  end
end