#Ensure the module's namespace exists, so plugin authors can
#abbreviate the namespace decls in their files.
module LintFu
  module Plugins
  end
end

plugins_dir = File.expand_path('../plugins', __FILE__)
Dir[File.join(plugins_dir, '*.rb')].each do |file|
  require file
end