module LintFu
  module Mixins
    module FileClassMethods
      def relative_path(base, path)
        base = File.expand_path(base)
        path = File.expand_path(path)
        raise Errno::ENOENT unless path.index(base) == 0
        return path[base.length+1..-1]
      end
    end
  end
end

class <<File
  include LintFu::Mixins::FileClassMethods
end