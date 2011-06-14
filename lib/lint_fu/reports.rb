module LintFu
  module Reports

  end
end

# The base class should be loaded first
require 'lint_fu/reports/base_writer'

# Everyone else can be loaded automagically
reports_dir = File.expand_path('../reports', __FILE__)
Dir[File.join(reports_dir, '*.rb')].each do |file|
  require file
end