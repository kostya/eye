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
    triggers.first.inspect.size.should > 100
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
    @process.schedule :start

    stub(@process).notify(:info, anything)
    mock(@process).notify(:error, anything)

    sleep 13

    # check flapping happens here

    @process.state_name.should == :unmonitored
    @process.watchers.keys.should == []
    @process.states_history.states.last(2).should == [:down, :unmonitored]
    @process.load_pid_from_file.should == nil
  end

  it "process flapping emulate with kill" do
    @process = process(@c.merge(:triggers => C.flapping(:times => 3, :within => 8)))

    @process.start

    3.times do
      die_process!(@process.pid)
      sleep 3
    end

    @process.state_name.should == :unmonitored
    @process.watchers.keys.should == []

    # ! should switched to unmonitored from down status
    @process.states_history.states.last(2).should == [:down, :unmonitored]
    @process.load_pid_from_file.should == nil
  end

  it "process flapping, and then send to start and fast kill, should ok started" do
    @process = process(@c.merge(:triggers => C.flapping(:times => 3, :within => 15)))

    @process.start

    3.times do
      die_process!(@process.pid)
      sleep 3
    end

    @process.state_name.should == :unmonitored
    @process.watchers.keys.should == []

    @process.start
    @process.state_name.should == :up

    die_process!(@process.pid)
    sleep 4
    @process.state_name.should == :up

    @process.load_pid_from_file.should == @process.pid
  end

  it "flapping not happens" do
    @process = process(@c)
    @process.schedule :start

    proxy(@process).schedule(:command => :restore)
    proxy(@process).schedule(:command => :check_crash)
    dont_allow(@process).schedule(:unmonitor)

    sleep 2

    2.times do
      die_process!(@process.pid)
      sleep 3
    end

    sleep 2

    @process.state_name.should == :up
    @process.load_pid_from_file.should == @process.pid
  end
end
