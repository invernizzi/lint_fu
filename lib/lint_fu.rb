# LintFu

class File
  def self.relative_path(base, path)
    base = File.expand_path(base)
    path = File.expand_path(path)
    raise Errno::ENOENT unless path.index(base) == 0
    return path[base.length..-1]
  end
end

class Sexp
  def to_ruby_string
    typ = self[0]

    case typ
      when :true
        return 'true'
      when :false
        return 'false'
      when :lit, :str
        return self[1].to_s
      when :array
        return self[1..-1].collect { |x| x.to_ruby }.inspect
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
        return result.inspect
      when :const
        return self[1].to_s
      when :colon2
        return self[1].to_ruby_string + '::' + self[2].to_ruby_string  
      else
        raise StandardError.new("Sexp cannot be converted to Ruby string " + self.to_s)
    end
  end

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