require File.dirname(__FILE__) + '/../spec_helper'

describe "Intergration" do
  before :each do
    @c = Eye::Controller.new($logger)
    @c.load(fixture("dsl/integration.eye"))
    @processes = @c.all_processes
    @p1 = @processes.detect{|c| c.name == 'sample1'}
    @p2 = @processes.detect{|c| c.name == 'sample2'}
    @p3 = @processes.detect{|c| c.name == 'forking'}
    @samples = @c.all_groups.detect{|c| c.name == 'samples'}
    sleep 8 # to ensure that all processes started

    @processes.size.should == 3
    @processes.map{|c| c.state_name}.uniq.should == [:up]
    @childs = @p3.childs.keys rescue []
  end

  after :each do
    @processes.each do |p|
      p.queue(:stop) if p.alive?
    end
    sleep 5
    @processes.each do |process|
      force_kill_process(process) if process.alive?
    end

    force_kill_pid(@old_pid1)
    force_kill_pid(@old_pid2)
    force_kill_pid(@old_pid3)
    (@childs || []).each do |pid|
      force_kill_pid(pid)
    end
  end

  it "status string" do
    str = <<S
int
  samples
    sample1(#{@p1.pid}): up
    sample2(#{@p2.pid}): up
  forking(#{@p3.pid}): up
    child(#{@p3.childs.keys[0]}): up
    child(#{@p3.childs.keys[1]}): up
    child(#{@p3.childs.keys[2]}): up
S

    @c.status_string.should == str
  end

  it "restart process group samples" do
    @old_pid1 = @p1.pid
    @old_pid2 = @p2.pid
    @old_pid3 = @p3.pid
    @c.send_command(:restart, "samples")
    sleep 11 # while they restarting

    @processes.map{|c| c.state_name}.uniq.should == [:up]
    @p1.pid.should_not == @old_pid1
    @p2.pid.should_not == @old_pid2
    @p3.pid.should == @old_pid3
  end

  it "restart process" do
    @old_pid1 = @p1.pid
    @old_pid2 = @p2.pid
    @old_pid3 = @p3.pid
    @c.send_command(:restart, "sample1")
    sleep 10 # while they restarting

    @processes.map{|c| c.state_name}.uniq.should == [:up]
    @p1.pid.should_not == @old_pid1
    @p2.pid.should == @old_pid2
    @p3.pid.should == @old_pid3
  end

  it "restart process forking" do
    @old_pid1 = @p1.pid
    @old_pid2 = @p2.pid
    @old_pid3 = @p3.pid
    @c.send_command(:restart, "forking")
    sleep 11 # while they restarting

    @processes.map{|c| c.state_name}.uniq.should == [:up]
    @p1.pid.should == @old_pid1
    @p2.pid.should == @old_pid2
    @p3.pid.should_not == @old_pid3
  end

  it "restart missing" do
    @old_pid1 = @p1.pid
    @old_pid2 = @p2.pid
    @old_pid3 = @p3.pid
    @c.send_command(:restart, "blabla").should == :nothing
    sleep 1
    @processes.map{|c| c.state_name}.uniq.should == [:up]
    @p1.pid.should == @old_pid1
    @p2.pid.should == @old_pid2
    @p3.pid.should == @old_pid3
  end

  describe "chain" do
    it "restart group with chain sync" do
      @samples.config.merge!(:chain => C.restart_sync)

      @old_pid1 = @p1.pid
      @old_pid2 = @p2.pid
      @old_pid3 = @p3.pid
      @c.send_command(:restart, "samples")
      sleep 15 # while they restarting

      @processes.map{|c| c.state_name}.uniq.should == [:up]
      @p1.pid.should_not == @old_pid1
      @p2.pid.should_not == @old_pid2
      @p3.pid.should == @old_pid3

      r1 = @p1.states_history.detect{|c| c.state == :restarting}.at
      r2 = @p2.states_history.detect{|c| c.state == :restarting}.at

      # >8 because, grace start, and grace stop added
      (r2 - r1).should > 8
    end

    it "restart group with chain async" do
      @samples.config.merge!(:chain => C.restart_async)

      @old_pid1 = @p1.pid
      @old_pid2 = @p2.pid
      @old_pid3 = @p3.pid
      @c.send_command(:restart, "samples")
      sleep 15 # while they restarting

      @processes.map{|c| c.state_name}.uniq.should == [:up]
      @p1.pid.should_not == @old_pid1
      @p2.pid.should_not == @old_pid2
      @p3.pid.should == @old_pid3

      r1 = @p1.states_history.detect{|c| c.state == :restarting}.at
      r2 = @p2.states_history.detect{|c| c.state == :restarting}.at

      # restart sended, in 5 seconds to each
      (r2 - r1).should be_within(0.2).of(5)
    end
  end

  it "stop group" do
    @old_pid1 = @p1.pid
    @old_pid2 = @p2.pid
    @old_pid3 = @p3.pid
    @c.send_command(:stop, "samples")
    sleep 7 # while they stopping

    @p1.state_name.should == :unmonitored
    @p2.state_name.should == :unmonitored
    @p3.state_name.should == :up

    Eye::System.pid_alive?(@old_pid1).should == false
    Eye::System.pid_alive?(@old_pid2).should == false
    Eye::System.pid_alive?(@old_pid3).should == true
  end

  it "stop process" do
    @old_pid1 = @p1.pid
    @old_pid2 = @p2.pid
    @old_pid3 = @p3.pid

    @c.send_command(:stop, "sample1")
    sleep 7 # while they stopping

    @p1.state_name.should == :unmonitored
    @p2.state_name.should == :up
    @p3.state_name.should == :up

    Eye::System.pid_alive?(@old_pid1).should == false
    Eye::System.pid_alive?(@old_pid2).should == true
    Eye::System.pid_alive?(@old_pid3).should == true
  end

  it "unmonitor process" do
    @old_pid1 = @p1.pid
    @old_pid2 = @p2.pid
    @old_pid3 = @p3.pid

    @c.send_command(:unmonitor, "sample1").should == "[sample1]"
    sleep 7 # while they stopping

    @p1.state_name.should == :unmonitored
    @p2.state_name.should == :up
    @p3.state_name.should == :up

    Eye::System.pid_alive?(@old_pid1).should == true
    Eye::System.pid_alive?(@old_pid2).should == true
    Eye::System.pid_alive?(@old_pid3).should == true
  end

  describe "remove" do
    it "remove group not monitoring anymore" do
      @old_pid1 = @p1.pid
      @old_pid2 = @p2.pid
      @old_pid3 = @p3.pid

      @c.send_command(:remove, "samples").should == "[samples]"
      sleep 7 # while 

      @c.all_processes.should == [@p3]
      @c.all_groups.map(&:name).should == ['__default__']

      Eye::System.pid_alive?(@old_pid1).should == true
      Eye::System.pid_alive?(@old_pid2).should == true
      Eye::System.pid_alive?(@old_pid3).should == true

      Eye::System.send_signal(@old_pid1)
      sleep 0.5
      Eye::System.pid_alive?(@old_pid1).should == false

      # noone up this
      sleep 2
      Eye::System.pid_alive?(@old_pid1).should == false
    end

    it "remove process not monitoring anymore" do
      @old_pid1 = @p1.pid
      @old_pid2 = @p2.pid
      @old_pid3 = @p3.pid

      @c.send_command(:remove, "sample1")
      sleep 7 # while 

      @c.all_processes.map(&:name).sort.should == %w{forking sample2}
      @c.all_groups.map(&:name).sort.should == %w{__default__ samples}

      Eye::System.pid_alive?(@old_pid1).should == true
      Eye::System.pid_alive?(@old_pid2).should == true
      Eye::System.pid_alive?(@old_pid3).should == true

      Eye::System.send_signal(@old_pid1)
      sleep 0.5
      Eye::System.pid_alive?(@old_pid1).should == false
    end

    it "remove application" do
      @old_pid1 = @p1.pid
      @old_pid2 = @p2.pid
      @old_pid3 = @p3.pid

      @c.send_command(:remove, "int")
      sleep 7 # while 

      @c.all_processes.should == []
      @c.all_groups.should == []
      @c.applications.should == []

      Eye::System.pid_alive?(@old_pid1).should == true
      Eye::System.pid_alive?(@old_pid2).should == true
      Eye::System.pid_alive?(@old_pid3).should == true

      Eye::System.send_signal(@old_pid1)
      sleep 0.5
      Eye::System.pid_alive?(@old_pid1).should == false

      actors = Celluloid::Actor.all.map(&:class)
      actors.should_not include(Celluloid::Chain)
      actors.should_not include(Eye::Process)
      actors.should_not include(Eye::Group)
      actors.should_not include(Eye::Application)
      actors.should_not include(Eye::Checker::Memory)
    end
  end

end