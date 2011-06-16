module LintFu::DSL
  if defined?(::BasicObject)
    BasicObject = ::BasicObject
  else
    BasicObject = ::Object
  end

  class SexpWrapper < BasicObject
    def self.parse(string)
      sexp = RubyParser.new.parse(string)
      any = SexpAny.new
      sexp = sexp.gsub( s(:call, s(:const, :ANY), :method, s(:arglist)), any )
      sexp = sexp.gsub( s(:call, s(:call, nil, any, any), :ANY, any), any )
      sexp
    end

    def initialize(sexp)
      @sexp = sexp
    end

    def =~(other)
      case other
        when Regexp
          !!(@sexp.to_ruby_string =~ other)
        when String
          @sexp.match(SexpWrapper.parse(other))
        else
          @sexp.any? { |x| x == other }
      end
    rescue Exception => e
      nil
    end

    def method_missing(method, *args)
      @sexp.__send__(method, *args)
    end
  end
end