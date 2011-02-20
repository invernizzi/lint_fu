module LintFu
  module Parser
    def self.parse_ruby(filename)
      contents = File.read(filename)
      sexp = RubyParser.new.parse(contents, filename)
      return sexp
    rescue SyntaxError => e
      e2 = SyntaxError.new "In #{filename}: #{e.message}"
      e2.set_backtrace(e.backtrace)
      raise e2
    end
  end
end