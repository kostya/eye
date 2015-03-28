require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Process::StatesHistory" do
  before :each do
    @h = Eye::Process::StatesHistory.new
  end

  it "should work" do
    @h << :up
    @h.push :down, 'bla'

    @h.states.should == [:up, :down]
    @h.last_state.should == :down
    @h.last_state_changed_at.should be_within(2.seconds).of(Time.now)
    @h.last[:reason].should == 'bla'
  end

  it "states for period" do
    @h.push :up,    nil, 5.minutes.ago
    @h.push :down,  nil, 4.minutes.ago
    @h.push :start, nil, 3.minutes.ago
    @h.push :stop,  nil, 2.minutes.ago
    @h.push :up,    nil, 1.minutes.ago
    @h.push :down,  nil, 0.minutes.ago

    @h.states_for_period(1.5.minutes).should == [:up, :down]
    @h.states_for_period(2.5.minutes).should == [:stop, :up, :down]
    @h.states_for_period(6.minutes).should == [:up, :down, :start, :stop, :up, :down]

    # with start_point
    @h.states_for_period(2.5.minutes, 5.minutes.ago).should == [:stop, :up, :down]
    @h.states_for_period(2.5.minutes, nil).should == [:stop, :up, :down]
    @h.states_for_period(2.5.minutes, 1.5.minutes.ago).should == [:up, :down]
    @h.states_for_period(2.5.minutes, Time.now).should == []
  end
end
