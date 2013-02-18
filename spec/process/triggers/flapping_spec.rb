require File.dirname(__FILE__) + '/../../spec_helper'

describe "Flapping" do
  before :each do
    @c = C.p1.merge(      
      :triggers => C.flapping(:times => 4, :within => 10)
    )    
  end

  it "should create trigger from config" do
    start_ok_process(@c)

    triggers = @process.triggers
    triggers.size.should == 1

    triggers.first.class.should == Eye::Trigger::Flapping
    triggers.first.within.should == 10
    triggers.first.times.should == 4
  end

  it "should check speedy flapping by default" do
    start_ok_process(C.p1)

    triggers = @process.triggers
    triggers.size.should == 1

    triggers.first.class.should == Eye::Trigger::Flapping
    triggers.first.within.should == 10
    triggers.first.times.should == 10
  end

  it "process flapping" do
    @process = process(@c.merge(:start_command => @c[:start_command] + " -r"))
    @process.start!

    stub(@process).notify(:warn, anything)
    mock(@process).notify(:crit, anything)

    sleep 13

    # check flapping happens here

    @process.state_name.should == :unmonitored
    @process.watchers.keys.should == []
  end

  it "process flapping emulate with kill" do
    @process = process(@c.merge(:triggers => C.flapping(:times => 3, :within => 7)))

    @process.start

    # 4 times because, flapping flag, check on next switch
    4.times do
      die_process!(@process.pid)
      sleep 3
    end

    @process.state_name.should == :unmonitored
    @process.watchers.keys.should == []
  end

  it "flapping not happens" do
    @process = process(@c)
    @process.start!

    proxy(@process).schedule(:start, anything)
    proxy(@process).schedule(:check_crush, anything)
    dont_allow(@process).schedule(:unmonitor)


    sleep 5

    # even if process die in middle
    die_process!(@process.pid)

    sleep 5

    @process.state_name.should == :up    
  end

end