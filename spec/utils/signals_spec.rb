require File.dirname(__FILE__) + '/../spec_helper'

class TestEnumerable
  include Celluloid

  def bla(x, sig)
    sleep(x)
    sig.signal(x)
  end
end

describe "signals methods" do
  before(:each) do
    @actor = TestEnumerable.new
  end

  after(:each) do
    @actor.terminate
  end

  describe "wait_signal" do
    it "ok1" do
      should_spend(1) do
        res = Eye::Utils.wait_signal(2) do |s|
          @actor.async.bla(1, s)
        end

        res.should == :ok
      end
    end

    it "timeouted1" do
      should_spend(0.5) do
        res = Eye::Utils.wait_signal(0.5) do |s|
          @actor.async.bla(1, s)
        end
        res.should == :timeouted
      end
    end
  end

end
