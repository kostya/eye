require File.dirname(__FILE__) + '/../spec_helper'

describe "Intergration restart" do
  before :each do
    start_controller do
      @controller.load_erb(fixture("dsl/integration.erb"))
    end

    @processes.size.should == 3
    @processes.map{|c| c.state_name}.uniq.should == [:up]
    @samples = @controller.all_groups.detect{|c| c.name == 'samples'}
  end

  after :each do
    stop_controller
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

end