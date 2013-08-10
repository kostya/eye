require File.dirname(__FILE__) + '/../spec_helper'

describe "Intergration" do
  before :each do
    start_controller do
      res = @controller.load_erb(fixture("dsl/integration.erb"))
      Marshal.dump(res).should_not include("ActiveSupport")
    end

    @processes.size.should == 3
    @processes.map{|c| c.state_name}.uniq.should == [:up]

    @samples = @controller.all_groups.detect{|c| c.name == 'samples'}
  end

  after :each do
    stop_controller
  end

  it "should be ok status string" do
    s = @controller.info_string.split("\n").size
    s.should >= 6
    s.should <= 8
    @controller.info_string.strip.size.should > 100
  end

  it "restart process group samples" do
    @controller.send_command(:restart, "samples")
    sleep 11 # while they restarting

    @processes.map{|c| c.state_name}.uniq.should == [:up]
    @p1.pid.should_not == @old_pid1
    @p2.pid.should_not == @old_pid2
    @p3.pid.should == @old_pid3
  end

  it "restart process" do
    @controller.send_command(:restart, "sample1")
    sleep 10 # while they restarting

    @processes.map{|c| c.state_name}.uniq.should == [:up]
    @p1.pid.should_not == @old_pid1
    @p2.pid.should == @old_pid2
    @p3.pid.should == @old_pid3
  end

  it "restart process forking" do
    @controller.send_command(:restart, "forking")
    sleep 11 # while they restarting

    @processes.map{|c| c.state_name}.uniq.should == [:up]
    @p1.pid.should == @old_pid1
    @p2.pid.should == @old_pid2
    @p3.pid.should_not == @old_pid3

    @p1.last_scheduled_reason.to_s.should == 'monitor by user'
    @p3.last_scheduled_reason.to_s.should == 'restart by user'
  end

  it "restart forking named child" do
    @p3.wait_for_condition(15, 0.3) { @p3.childs.size == 3 }
    @childs = @p3.childs.keys
    @childs.size.should == 3
    dead_pid = @childs.sample

    @controller.send_command(:restart, "child-#{dead_pid}").should == {:result => ["int:forking:child-#{dead_pid}"]}
    sleep 11 # while it

    new_childs = @p3.childs.keys
    new_childs.size.should == 3
    new_childs.should_not include(dead_pid)
    (@childs - [dead_pid]).each do |pid|
      new_childs.should include(pid)
    end
  end

  it "restart missing" do
    @controller.send_command(:restart, "blabla").should == {:result => []}
    sleep 1
    @processes.map{|c| c.state_name}.uniq.should == [:up]
    @p1.pid.should == @old_pid1
    @p2.pid.should == @old_pid2
    @p3.pid.should == @old_pid3
  end


  it "stop group" do
    @controller.send_command(:stop, "samples")
    sleep 7 # while they stopping

    @p1.state_name.should == :unmonitored
    @p2.state_name.should == :unmonitored
    @p3.state_name.should == :up

    Eye::System.pid_alive?(@old_pid1).should == false
    Eye::System.pid_alive?(@old_pid2).should == false
    Eye::System.pid_alive?(@old_pid3).should == true

    sth = @p1.states_history.last
    sth[:reason].to_s.should == 'stop by user'
    sth[:state].should == :unmonitored
  end

  it "stop process" do
    @controller.send_command(:stop, "sample1")
    sleep 7 # while they stopping

    @p1.state_name.should == :unmonitored
    @p2.state_name.should == :up
    @p3.state_name.should == :up

    Eye::System.pid_alive?(@old_pid1).should == false
    Eye::System.pid_alive?(@old_pid2).should == true
    Eye::System.pid_alive?(@old_pid3).should == true
  end

  it "unmonitor process" do
    @controller.send_command(:unmonitor, "sample1").should == {:result => ["int:samples:sample1"]}
    sleep 7 # while they stopping

    @p1.state_name.should == :unmonitored
    @p2.state_name.should == :up
    @p3.state_name.should == :up

    Eye::System.pid_alive?(@old_pid1).should == true
    Eye::System.pid_alive?(@old_pid2).should == true
    Eye::System.pid_alive?(@old_pid3).should == true
  end

  it "send signal to process throught all schedules" do
    mock(@p1).signal('usr2')
    mock(@p2).signal('usr2')
    mock(@p3).signal('usr2')

    @controller.signal('usr2', "int").should == {:result => ["int"]}
    sleep 3 # while they gettings

    @p1.last_scheduled_command.should == :signal
    @p1.last_scheduled_reason.to_s.should == 'signal by user'

    mock(@p1).signal('usr1')
    @controller.signal('usr1', 'sample1')
    sleep 0.5
  end

end