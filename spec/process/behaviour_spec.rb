require File.dirname(__FILE__) + '/../spec_helper'

describe "Behaviour" do
  before :each do
    @process = process C.p1
  end

  describe "syncer" do
    it "restart process" do
      should_spend(2.5, 0.3) do
        @process.sync_call(:command => :start)
      end

      should_spend(3.0, 0.3) do
        @process.sync_call(:command => :restart)
      end

      @process.state_name.should == :up
      @process.states_history.states.should == [:unmonitored, :starting, :up, :restarting, :stopping, :down, :starting, :up]
    end
  end
end
