When /I run a scan/ do
  Dir.chdir($app_root) do
    output_file = Tempfile.new('lint_fu') ; output_file.close
    output_file = output_file.path

    runshell("lint_fu scan --output #{output_file} --format marshal")
    @scan = Marshal.load(File.read(output_file))
  end
end

Then /^the scan should contain (no|a|an|[0-9+]) instances? of ([A-Z][A-Za-z0-9]+)$/ do |count, type|
  count = case count
            when 'no': 0
            when 'an': 1
            else count.to_i
          end

  selected_issues = @scan.issues.select { |i| i.class.name.index(type) != nil }
  begin
    selected_issues.size.should == count
  rescue Exception => e
    selected_issues.each do |issue|
      Cucumber.logger.debug("Issue at line #{issue.sexp.line}: #{issue.sexp.to_ruby_string}\n")
    end
    raise e
  end
end

Then /^the scan should contain (no|a|an|[0-9+]) ?(total|genuine|blessed)? issues?$/ do |count, kind|
  count = case count
            when 'no': 0
            when 'an': 1
            else count.to_i
          end
  kind  ||= 'total'

  case kind
    when 'total'
      @scan.issues.size.should == count
    when 'genuine'
      @scan.issues.reject { |i| @scan.blessed?(i) }.size.should == count
    when 'blessed'
      @scan.issues.select { |i| @scan.blessed?(i) }.size.should == count
  end
end