module RunShell
  class ShellCommandFailed < Exception

  end

  # Runs a shell command and pipes output to console.
  def runshell(cmd, ignoreerrors=false)
    log = !!(Cucumber.logger)

    Cucumber.logger.debug("+ #{cmd}") if log

    IO.popen("#{cmd} 2>&1", 'r') do |output|
      output.sync = true
      done = false
      while !done
        begin
          Cucumber.logger.debug(output.readline) if log
        rescue EOFError
          done = true
        end
      end
    end

    raise ShellCommandFailed, "Exit code #{$?.exitstatus}" unless (ignoreerrors || $?.success?)
    return $?.exitstatus
  end

  # for Windows-specific tasks.
  def is_windows?
    return !!(RUBY_PLATFORM =~ /mswin/)
  end
end

World do
  world = Object.new
  world.extend(RunShell)
  world
end
