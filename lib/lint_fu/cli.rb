module LintFu
  module CLI
    BANNER = <<EOS
Lint-fu finds security defects in Ruby code.

Usage:
       lint_fu [options]
where [options] are:
EOS

    def self.run
      commands = []
      ObjectSpace.each_object(Class) do |c|
        commands << c.to_s.underscore if c.superclass == Command
      end

      opts = Trollop::options do
        version "Lint-Fu #{Gem.loaded_specs['lint_fu'].version} (c) 2011 Tony Spataro"
        banner BANNER
        stop_on commands
      end

      cmd_name = ARGV.shift || 'scan'
      sym = cmd_name.camelize.to_sym

      begin
        klass = const_get(sym)
        raise NameError unless klass.superclass == Command
      rescue NameError => e
        Trollop::die "Unknown command #{cmd_name}"
      end

      cmd = klass.new(opts)
      return cmd.run
    rescue Interrupt => e
      puts "Interrupt; exiting without completing task."
      exit(-1)
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