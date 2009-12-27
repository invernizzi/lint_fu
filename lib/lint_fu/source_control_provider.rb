module LintFu
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

  class ProviderNotInstalled < ProviderError
    def initialize(provider)
      super("The #{provider.name} source control provider does not seem to be installed on this system.")
    end
  end

  class SourceControlProvider
    @@subclasses = Set.new

    # Inherited callback to ensure this base class knows about all derived classes.
    def self.inherited(base)
      @@subclasses << base
    end

    # Instantiate the appropriate Provider subclass for a given directory.
    def self.for_directory(path)
      @@subclasses.each do |provider|
        begin
          return provider.new(path)
        rescue Exception => e
          next
        end
      end

      return nil
    end
    
    def initialize(path)
      @root = path
    end

    def excerpt(file, range, options={})
      blame   = options.has_key?(:blame)   ? options[:blame] : true
      raise ProviderError, "Blame is not supported for this source control provider" if blame

      Dir.chdir(@root) do
        start_line = range.first
        end_line   = range.last
        io         = File.open(File.relative_path(@root, file), 'r')
        lines      = io.readlines
        return lines[(start_line-1)..(end_line-1)]
      end
    end
  end
end