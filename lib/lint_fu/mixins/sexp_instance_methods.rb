module LintFu
  class TranslationFailure < Exception

  end

  module Mixins
    module SexpInstanceMethods
      WHOLE_LINE_COMMENT = /^\s*#/

      def deep_clone
        Marshal.load(Marshal.dump(self))
      end

      # Return a version of this Sexp that preserves the structure of the original, but with
      # any specific names, quantities or other values replaced with nil. The fingerprint of
      # a given chunk of code will tend to remain the same over time, even if variable names
      # or other inconsequential details are changed.
      def fingerprint
        #TODO actually implement this method
        self
      end

      # Generate a human-readable description for this sexp that is similar to source code.
      def to_ruby_string
        Ruby2Ruby.new.process(self.deep_clone)
      end

      # Translate a sexp containing a Ruby data literal (string, int, array, hash, etc) into
      # the equivalent Ruby object.
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
            raise TranslationFailure.new("Cannot convert Sexp to Ruby object (expression at #{self.file}:#{self.line}): " + self.to_s)
        end
      end

      def constant?
        typ = self[0]

        case typ
          when :call
            target = self[1]
            method = self[2]
            params = self[3]
            return target.respond_to?(:constant?) && target.constant? &&
                   params.respond_to?(:constant?) && params.constant?
          when :true, :false, :lit, :str
            return true
          when :array, :arglist
            contents = self[1..-1]
            return contents.all? { |sexp| sexp.constant? }
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

      def find_recursively(&test)
        return self if test.call(self)

        self.each do |child|
          found = child.find_recursively(&test) if (Sexp === child)
          return found if found
        end

        return nil
      end

      def find_all_recursively(results=nil, &test)
        results ||= []
        results << self if test.call(self)

        self.each do |child|
          child.find_all_recursively(results, &test) if (Sexp === child)
        end

        return nil if results.empty?
        return results
      end

      def preceding_comment_range
        unless @preceding_comment_range
          cont = File.readlines(self.file)

          comments = ''

          max_line = self.line - 1 - 1
          max_line = 0 if max_line < 0
          min_line = max_line

          while cont[min_line] =~ WHOLE_LINE_COMMENT && min_line >= 0
            min_line -= 1
          end

          if cont[max_line] =~ WHOLE_LINE_COMMENT
            min_line +=1 unless min_line == max_line
            @preceding_comment_range = LintFu::Core::FileRange.new(self.file, min_line+1, max_line+1, cont[min_line..max_line])
          else
            @preceding_comment_range = LintFu::Core::FileRange::NONE
          end
        end

        if @preceding_comment_range == LintFu::Core::FileRange::NONE
          return nil
        else
          return @preceding_comment_range
        end
      end
      
      def preceding_comments
        range = preceding_comment_range
        return [] unless range
        return range.content
      end

      def blessings
        @blessings ||= LintFu::Core::Blessing.parse(self.preceding_comments, self)
      end
    end
  end
end

Sexp.instance_eval do
  include LintFu::Mixins::SexpInstanceMethods
end
