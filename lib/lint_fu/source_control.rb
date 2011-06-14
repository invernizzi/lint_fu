module LintFu
  module SourceControl
    class ProviderError < Exception
      def initialize(*args)
        if args.length == 2 && args[0].kind_of?(LintFu::SourceControlProvider)
          provider = args[0]
          path     = args[1]
          super("The #{provider.class.name} source control provider does not recognize #{path} as a valid repository")
        else
          super(*args)
        end
      end
    end

    # Instantiate the appropriate Provider subclass for a given directory.
    def self.for_directory(path)
      klasses = LintFu::SourceControl::BaseProvider.subclasses - [LintFu::SourceControl::Unknown]

      klasses.each do |provider|
        begin
          return provider.new(path)
        rescue Exception => e
          next
        end
      end

      return LintFu::SourceControl::Unknown.new(path)
    end
  end
end

# The base class should be loaded first
require 'lint_fu/source_control/base_provider'

# Everyone else can be loaded automagically
cli_dir = File.expand_path('../source_control', __FILE__)
Dir[File.join(cli_dir, '*.rb')].each do |file|
  require file
end