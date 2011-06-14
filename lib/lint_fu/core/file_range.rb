module LintFu::Core
  class FileRange
    attr_reader :filename, :min_line, :max_line

    def initialize(filename, min_line, max_line=nil, content=nil)
      @filename = File.expand_path(filename)
      @min_line = min_line
      @max_line = max_line || min_line
      @content = content
    end

    def line
      min_line
    end

    def content
      unless @content
        #TODO optimize
        all_content = File.readlines(self.file)

        min_line = [self.min_line - 1, 0].max
        max_line = [self.max_line - 1, all_content.size - 1].max
        @content = all_content[min_line..max_line]
      end

      return @content
    end

    def ==(other)
      (self.filename == other.filename) &&
      (self.min_line == other.min_line) &&
      (self.max_line == other.max_line)
    end

    def include?(range)
      (self.filename == range.filename) &&
      (self.min_line <= range.min_line) &&
      (self.max_line >= range.max_line)
    end

    NONE = FileRange.new('/dev/null', 0)
  end
end