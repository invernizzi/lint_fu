# LintFu

class File
  def self.relative_path(base, path)
    base = File.expand_path(base)
    path = File.expand_path(path)
    raise Errno::ENOENT unless path.index(base) == 0
    return path[base.length+1..-1]
  end
end

class Symbol
  def to_ruby_string
    self.to_s
  end
end

class Sexp
  #Generate a human-readable description for this sexp that is similar to source code.
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
      when :colon3
        return '::' + self[1].to_ruby_string
      else
        raise StandardError.new("Sexp cannot be converted to Ruby string " + self.to_s)
    end
  end

  # Translate a sexp containing a Ruby data literal (string, int, array, hash, etc) into the equivalent Ruby object.
  def to_ruby(options={})
    typ = self[0]

    case typ
      when :true
        return true
      when :false
        return false
      when :lit, :str
        return self[1]
      when :array, :arglist
        return self[1..-1].collect { |x| x.to_ruby(options) }
      when :hash
        result = {}
        key, value = nil, nil
        flipflop = false
        self[1..-1].each do |token|
          if flipflop
            value = token
            result[key.to_ruby(options)] = value.to_ruby(options)
          else
            key = token
          end
          flipflop = !flipflop
        end
        return result
      else
        return options[:partial] if options.has_key?(:partial)
        raise StandardError.new("Cannot convert Sexp to Ruby object: " + self.to_s)
    end
  end

  def constant?
    typ = self[0]

    case typ
      when :true, :false, :lit, :str
        return true
      when :array, :arglist
        self[1..-1].each { |sexp| return false unless sexp.constant? }
        return true
      when :hash
        result = {}
        key, value = nil, nil
        flipflop = false
        self[1..-1].each do |token|
          if flipflop
            value = token
            return false unless key.constant? && value.constant?
          else
            key = token
          end
          flipflop = !flipflop
        end
        return true
      else
        return false
    end
  end
end