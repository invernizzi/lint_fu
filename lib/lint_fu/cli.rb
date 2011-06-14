module LintFu
  module CLI
    BANNER = <<EOS
Lint-fu finds security defects in Ruby code.

Usage:
       lint_fu <scan|prune> [options]

where [options] are:
EOS

    def self.run
      commands = BaseCommand.subclasses.map { |k| k.to_s.underscore }

      opts = Trollop::options do
        version "Lint-Fu #{Gem.loaded_specs['lint_fu'].version} (c) 2011 Tony Spataro"
        banner BANNER
        stop_on commands
        opt :format, "Report format: #{LintFu::CLI::Scan::VISIBLE_FORMATS.join(', ')}",
                     :type=>String
        opt :output, "Output file",
                     :type=>String
        opt :quiet, "Suppress output other than error and warning messages"
        opt :fail, "Exit with failure if issues are found"
      end

      cmd_name = ARGV.shift || 'scan'
      sym = cmd_name.camelize.to_sym

      begin
        klass = const_get(sym)
        raise NameError unless klass.superclass == BaseCommand
      rescue NameError => e
        Trollop::die "Unknown command #{cmd_name}"
      end

      if opts[:format] && ! LintFu::CLI::Scan::REPORT_FORMATS.has_key?(opts[:format])
        Trollop::die "Unrecognized report format #{opts[:format]}"
      end

      cmd = klass.new(opts)
      return cmd.run
    rescue Interrupt => e
      exit(-1)
    end
  end
end

# The base class should be loaded first
require 'lint_fu/cli/base_command'

# Everyone else can be loaded automagically
cli_dir = File.expand_path('../cli', __FILE__)
Dir[File.join(cli_dir, '*.rb')].each do |file|
  require file
end