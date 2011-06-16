# Gemfile dependencies
require 'trollop'
require 'ruby_parser'
require 'sexp_processor'
require 'ruby2ruby'
require 'active_support'
require 'active_support/core_ext/string/inflections'
require 'active_support/inflections'
require 'builder'
require 'redcloth'

# Mixins for various Ruby builtins and classes defined by other gems
require 'lint_fu/mixins'

# Main lint-fu modules
require 'lint_fu/core'
require 'lint_fu/parser'
require 'lint_fu/source_control'
require 'lint_fu/reports'

# Plugins
require 'lint_fu/plugins'

# Domain-Specific Language and Command-Line Interface
require 'lint_fu/dsl'
require 'lint_fu/cli'
