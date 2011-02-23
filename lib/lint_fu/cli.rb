module LintFu
  module CLI
    DEFAULT_COMMAND = 'scan'

    def self.run_command(argv)
      #the command name is the first word of argv that doesn't
      #begin with a hyphen or a (Windows-switch-style slash)
      name = argv.detect { |w| w !~ %r(^[-/]) } || DEFAULT_COMMAND
      sym = name.camelize.to_sym

      begin
        klass = const_get(sym)
        raise NameError unless klass.superclass == Command
      rescue NameError => e
        raise NameError, "Unknown command #{name}"
      end

      cmd = klass.new
      #TODO parse options and send them in
      return cmd.run({})
    end
  end
end

# The base class (Command) should be loaded first
require 'lint_fu/cli/command'

# Everyone else can be loaded automagically
cli_dir = File.expand_path('../cli', __FILE__)
Dir[File.join(cli_dir, '*.rb')].each do |file|
  require file
end