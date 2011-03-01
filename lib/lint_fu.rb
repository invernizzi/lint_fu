# Load Ruby std library classes we depend upon
require 'set'
require 'digest/md5'
require 'digest/sha1'

# Activate the various gems we depend on
require 'trollop'
require 'ruby_parser'
require 'sexp_processor'
require 'ruby2ruby'
require 'active_support'
require 'builder'
require 'redcloth'

# Mixins for various Ruby builtins and classes defined by other gems
require 'lint_fu/mixins'

# Core lint-fu sources
require 'lint_fu/parser'
require 'lint_fu/eidos'
require 'lint_fu/eidos_container'
require 'lint_fu/eidos_factory'
require 'lint_fu/source_control_provider'
require 'lint_fu/issue'
require 'lint_fu/checker'
require 'lint_fu/visitor'
require 'lint_fu/scan'
require 'lint_fu/report'

# source control providers
require 'lint_fu/source_control/git'

# plugins
require 'lint_fu/plugins'

# command line interface
require 'lint_fu/cli'
