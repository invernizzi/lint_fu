require 'lint_fu/plugins/action_pack'
require 'lint_fu/plugins/active_record'

require 'lint_fu/plugins/rails/application_eidos'
require 'lint_fu/plugins/rails/application_eidos_builder'
require 'lint_fu/plugins/rails/buggy_eager_load_checker'
require 'lint_fu/plugins/rails/log_information_leak_checker'
require 'lint_fu/plugins/rails/sql_injection_checker'
require 'lint_fu/plugins/rails/unsafe_find_checker'
require 'lint_fu/plugins/rails/issue_builder'

module LintFu::Plugins
  module Rails
    def self.applies_to?(dir)
      File.exist?(File.join(dir, 'app')) &&
      File.exist?(File.join(dir, 'config', 'environments')) &&
      File.exist?(File.join(dir, 'config', 'environment.rb'))
    end

    def self.context_builder_for(dir)
      return nil unless applies_to?(dir)
      ApplicationEidosBuilder.new(dir)
    end

    def self.issue_builder_for(dir)
      return nil unless applies_to?(dir)
      IssueBuilder.new(dir)
    end
  end
end
