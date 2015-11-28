require File.dirname(__FILE__) + '/../spec_helper'

describe "Behaviour" do
  before :each do
    @process = process C.p1
  end

  describe "sync with signals" do
    it "restart process with signal" do
      should_spend(2.5, 0.3) do
        c = Celluloid::Condition.new
        @process.send_call(:command => :start, :signal => c)
        c.wait
      end

      should_spend(3.0, 0.3) do
        c = Celluloid::Condition.new
        @process.send_call(:command => :restart, :signal => c)
        c.wait
      end

      @process.state_name.should == :up
      @process.states_history.states.should == [:unmonitored, :starting, :up, :restarting, :stopping, :down, :starting, :up]
    end
  end
end
