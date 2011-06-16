require File.expand_path('../../../spec_helper', __FILE__)

def parse(string)
  RubyParser.new.parse(string)
end

describe LintFu::Mixins::SexpInstanceMethods do
  describe :preceding_comment_range do
    it 'has tests'
  end

  describe :match? do
    context 'searching for foo.ANY(ANY)' do
      it 'should match' do
        @tgt = s(:call, SexpAny, SexpAny, s(:arglist, SexpAny))
        parse('foo.joe').match?(@tgt).should be_true
        parse('foo[7]').match?(@tgt).should be_true
        parse('foo.joe(a,b,c)').match?(@tgt).should be_true
      end
    end

    context 'searching for ANY.foo' do
      before(:each) do
        @tgt = s(:call, SexpAny, :foo, s(:arglist))
      end

      it 'matches calls with targets' do
        parse('nil.foo').match?(@tgt).should be_true
        parse('bar.foo').match?(@tgt).should be_true
        parse('bar.baz.binky.foo').match?(@tgt).should be_true
      end

      it 'matches target-less calls' do
        parse('foo').match?(@tgt).should be_true
      end
    end
  end

  describe :replace do
    it 'handles literal search/replace' do
      sexp = s(:call, nil, :foo, s(:arglist))
      sexp.replace(:call, 'cake').should == s('cake', nil, :foo, s(:arglist))
      sexp.replace(nil, 'cake').should == s(:call, 'cake', :foo, s(:arglist))
      sexp.replace(s(:arglist), 'cake').should == s(:call, nil, :foo, 'cake')
    end

    it 'handles wildcard search' do
      sexp = parse('User.first(:conditions=>{:email=>params[:email]})')
      params_call = s(:call, s(:call, nil, :params, s(:arglist)), :[], SexpAny)
      sexp.replace(params_call, 'cake').to_ruby_string.should =~ /cake/
    end
  end
end
