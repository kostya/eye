require File.dirname(__FILE__) + '/../spec_helper'

describe "Intergration chains" do
  before :each do
    start_controller do
      @controller.load_erb(fixture("dsl/integration.erb"))
    end

    @samples = @controller.all_groups.detect{|c| c.name == 'samples'}
    @samples.config.merge!(:chain => C.restart_async)
  end

  after :each do
    stop_controller
  end

  it "restart group with chain sync" do
    @samples.config.merge!(:chain => C.restart_sync)

    @controller.send_command(:restart, "samples")
    sleep 15 # while they restarting

    @processes.map{|c| c.state_name}.uniq.should == [:up]
    @p1.pid.should_not == @old_pid1
    @p2.pid.should_not == @old_pid2
    @p3.pid.should == @old_pid3

    r1 = @p1.states_history.detect{|c| c[:state] == :restarting}[:at]
    r2 = @p2.states_history.detect{|c| c[:state] == :restarting}[:at]

    # >8 because, grace start, and grace stop added
    (r2 - r1).should >= 8
  end

  it "restart group with chain async" do
    @controller.send_command(:restart, "samples")
    sleep 15 # while they restarting

    @processes.map{|c| c.state_name}.uniq.should == [:up]
    @p1.pid.should_not == @old_pid1
    @p2.pid.should_not == @old_pid2
    @p3.pid.should == @old_pid3

    r1 = @p1.states_history.detect{|c| c[:state] == :restarting}[:at]
    r2 = @p2.states_history.detect{|c| c[:state] == :restarting}[:at]

    # restart sent, in 5 seconds to each
    (r2 - r1).should be_within(0.2).of(5)
  end

  it "if processes dead in chain restart, nothing raised" do
    @controller.send_command(:restart, "samples")
    sleep 3

    @pids += @controller.all_processes.map(&:pid) # to ensure kill this processes after spec

    @p1.terminate
    @p2.terminate

    sleep 3

    # nothing happens
    @samples.alive?.should == true
  end

  it "chain breaker breaks current chain and all pending requests" do
    @controller.send_command(:restart, "samples")
    @controller.send_command(:stop, "samples")
    sleep 0.5

    @samples.current_scheduled_command.should == :restart
    @samples.scheduler_actions_list.should == [:stop]

    @controller.command(:break_chain, "samples")
    sleep 3
    @samples.current_scheduled_command.should == :restart
    sleep 2
    @samples.current_scheduled_command.should == nil
    @samples.scheduler_actions_list.should == []

    sleep 1

    # only first process should be restarted
    @p1.last_scheduled_command.should == :restart
    @p2.last_scheduled_command.should == :monitor
  end

end