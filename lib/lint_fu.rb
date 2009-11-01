# LintFu

class Sexp
  def to_ruby
    typ = self[0]

    case typ
      when :true
        return true
      when :false
        return false
      when :lit, :str
        return self[1]
      when :array
        return self[1..-1].collect { |x| x.to_ruby }
      when :hash
        result = {}
        key, value = nil, nil
        flipflop = false
        self[1..-1].each do |token|
          if flipflop
            value = token
            result[key.to_ruby] = value.to_ruby
          else
            key = token
          end
          flipflop = !flipflop
        end
        return result
      else
        raise StandardError.new("Sexp cannot be converted to Ruby data " + self.to_s)
    end
  end
end