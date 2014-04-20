require File.dirname(__FILE__) + '/../spec_helper'

describe "Process with use_leaf_child" do

  before { @process = process(C.p6) }

  # monitor leaf child in process tree
  # sh -c
  #   sleep 10

  # pid should of `sleep 10`

  it "start" do
    @process.start
    ps = `ps ax | grep #{@process.pid} | grep -v grep`
    ps.should include('sleep 10')
    ps.should_not include('sh -c')
    @process.pid.should be
    @process.parent_pid.should be
    @process.parent_pid.should_not == @process.pid
    @process.state_name.should == :up

    Eye::System.pid_alive?(@process.pid).should == true
    Eye::System.pid_alive?(@process.parent_pid).should == true
  end

  it "stop" do
    @process.start
    Eye::System.pid_alive?(@process.pid).should == true
    Eye::System.pid_alive?(@process.parent_pid).should == true
    `ps ax | grep #{C.p6_word} | grep -v grep`.should_not be_blank

    @process.stop
    `ps ax | grep #{C.p6_word} | grep -v grep`.should be_blank

    # parent_pid also should die by itself
    Eye::System.pid_alive?(@process.pid).should == false
    Eye::System.pid_alive?(@process.parent_pid).should == false
  end
end
