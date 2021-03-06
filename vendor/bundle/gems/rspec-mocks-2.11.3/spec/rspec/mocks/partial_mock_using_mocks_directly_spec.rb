require 'spec_helper'

module RSpec::Mocks
  describe "PartialMockUsingMocksDirectly" do
    let(:klass) do
      Class.new do
        module MethodMissing
          remove_method :method_missing rescue nil
          def method_missing(m, *a, &b)
            if m == :captured_by_method_missing
              "response generated by method missing"
            else
              super(m, *a, &b)
            end
          end
        end

        extend MethodMissing
        include MethodMissing

        def existing_method
          :original_value
        end

      end
    end

    let(:obj) { klass.new }

    # See http://rubyforge.org/tracker/index.php?func=detail&aid=10263&group_id=797&atid=3149
    # specify "should clear expectations on verify" do
    #     obj.should_receive(:msg)
    #     obj.msg
    #     obj.rspec_verify
    #     lambda do
    #       obj.msg
    #     end.should raise_error(NoMethodError)
    #   
    # end
    it "fails when expected message is not received" do
      obj.should_receive(:msg)
      lambda do
        obj.rspec_verify
      end.should raise_error(RSpec::Mocks::MockExpectationError)
    end

    it "fails when message is received with incorrect args" do
      obj.should_receive(:msg).with(:correct_arg)
      lambda do
        obj.msg(:incorrect_arg)
      end.should raise_error(RSpec::Mocks::MockExpectationError)
      obj.msg(:correct_arg)
    end

    it "passes when expected message is received" do
      obj.should_receive(:msg)
      obj.msg
      obj.rspec_verify
    end

    it "passes when message is received with correct args" do
      obj.should_receive(:msg).with(:correct_arg)
      obj.msg(:correct_arg)
      obj.rspec_verify
    end

    it "restores the original method if it existed" do
      obj.existing_method.should equal(:original_value)
      obj.should_receive(:existing_method).and_return(:mock_value)
      obj.existing_method.should equal(:mock_value)
      obj.rspec_verify
      obj.existing_method.should equal(:original_value)
    end

    context "with an instance method handled by method_missing" do
      it "restores the original behavior" do
        obj.captured_by_method_missing.should eq("response generated by method missing")
        obj.stub(:captured_by_method_missing) { "foo" }
        obj.captured_by_method_missing.should eq("foo")
        obj.rspec_reset
        obj.captured_by_method_missing.should eq("response generated by method missing")
      end
    end

    context "with a class method handled by method_missing" do 
      it "restores the original behavior" do
        klass.captured_by_method_missing.should eq("response generated by method missing")
        klass.stub(:captured_by_method_missing) { "foo" }
        klass.captured_by_method_missing.should eq("foo")
        klass.rspec_reset
        klass.captured_by_method_missing.should eq("response generated by method missing")
      end
    end
  end
end
