# -*- encoding : utf-8 -*-
require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Process::StatesHistory" do
  before :each do
    @h = Eye::Process::StatesHistory.new    
  end

  it "should work" do
    @h << :up
    @h.push :down

    @h.states.should == [:up, :down]
    @h.last_state.should == :down
    @h.last_state_changed_at.should be_within(2.seconds).of(Time.now)
  end

  it "states for period" do
    @h.push :up,    5.minutes.ago
    @h.push :down,  4.minutes.ago
    @h.push :start, 3.minutes.ago
    @h.push :stop,  2.minutes.ago
    @h.push :up,    1.minutes.ago
    @h.push :down,  0.minutes.ago

    @h.states_for_period(1.5.minutes).should == [:up, :down]
    @h.states_for_period(2.5.minutes).should == [:stop, :up, :down]
    @h.states_for_period(6.minutes).should == [:up, :down, :start, :stop, :up, :down]
  end

  it "seq?" do
    @h << :unmonitored
    @h << :starting
    @h << :down
    @h << :starting

    @h.seq?([:starting, :down, :starting]).should == true
    @h.seq?(:starting, :down, :starting).should == true
    @h.seq?([:starting, :down]).should == true

    @h.seq?([:starting, :up]).should == false
    @h.seq?([:starting, :starting]).should == false
    @h.seq?(:starting, :starting).should == false

    @h.seq?(:down).should == true
    @h.seq?(:up).should == false
  end

  it "any?" do
    @h << :unmonitored
    @h << :starting
    @h << :down
    @h << :starting

    @h.any?([:starting, :down, :starting]).should == true
    @h.any?(:starting, :down, :starting).should == true
    @h.any?(:up).should == false
    @h.any?(:up, :stopping).should == false
    @h.any?(:up, :down).should == true
    @h.any?(:down).should == true
  end

  it "noone?" do
    @h << :unmonitored
    @h << :starting
    @h << :down
    @h << :starting

    @h.noone?(:up, :stopping).should == true
    @h.noone?(:up, :down).should == true
  end

  it "end?" do
    @h << :unmonitored
    @h << :starting
    @h << :down
    @h << :starting

    @h.end?(:down, :starting).should == true    
    @h.end?(:starting, :down).should == false

    @h.end?(:starting).should == true
    @h.end?(:down).should == false

    @h.end?(:starting, :down, :starting).should == true    
    @h.end?(:unmonitored, :starting, :down, :starting).should == true    
  end

  it "all?" do
    @h << :unmonitored
    @h << :starting
    @h << :down
    @h << :starting

    @h.all?([:starting, :down, :starting]).should == false    
    @h.all?(:starting, :down, :starting).should == false
    @h.all?(:starting, :down, :starting, :unmonitored).should == true
    @h.all?(:down, :starting, :unmonitored).should == true

    @h.all?(:up).should == false
    @h.all?(:up, :stopping).should == false
    @h.all?(:up, :down).should == false
    @h.all?(:down).should == false
  end  

  it "state_count" do
    @h << :unmonitored
    @h << :starting
    @h << :down
    @h << :starting

    @h.state_count(:down).should == 1
    @h.state_count(:starting).should == 2
    @h.state_count(:up).should == 0
  end

end