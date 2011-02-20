module LintFu
  module Plugins
    def self.register(mod)
      @registry ||= Set.new
      @registry << mod
    end
  end
end

plugins_dir = File.expand_path('../plugins', __FILE__)
Dir[File.join(plugins_dir, '*.rb')].each do |file|
  require file
end