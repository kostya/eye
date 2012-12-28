require File.dirname(__FILE__) + '/../spec_helper'

describe "Intergration" do
  before :each do
    @c = controller_new
    @c.load(fixture("dsl/integration.eye"))
    @processes = @c.all_processes
    @p1 = @processes.detect{|c| c.name == 'sample1'}
    @p2 = @processes.detect{|c| c.name == 'sample2'}
    @p3 = @processes.detect{|c| c.name == 'forking'}
    @samples = @c.all_groups.detect{|c| c.name == 'samples'}
    sleep 10 # to ensure that all processes started

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
    
    File.delete(File.join(C.sample_dir, "lock1.lock")) rescue nil
    File.delete(File.join(C.sample_dir, "lock2.lock")) rescue nil
  end

  it "status string" do
    @c.status_string.split("\n").size.should == 8
    @c.status_string.strip.size.should > 100
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

    it "remove by mask" do
      @old_pid1 = @p1.pid
      @old_pid2 = @p2.pid
      @old_pid3 = @p3.pid

      @c.send_command(:remove, "sam*").should == "[samples, sample1, sample2]"
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
  end

  it "load another config, with same processes but changed names" do
    @old_pid1 = @p1.pid
    @old_pid2 = @p2.pid
    @old_pid3 = @p3.pid
  
    @c.load(fixture("dsl/integration2.eye"))
    sleep 10
    
    # @p1, @p2 recreates
    # @p3 the same    
   
    procs = @c.all_processes 
    @p1_ = procs.detect{|c| c.name == 'sample1_'}
    @p2_ = procs.detect{|c| c.name == 'sample2_'}
    @p3_ = procs.detect{|c| c.name == 'forking'}
    
    @p3.object_id.should == @p3_.object_id
    @p1.alive?.should == false
    @p1_.alive?.should == true

    @p2.alive?.should == false
    @p2_.alive?.should == true
    
    @p1_.pid.should == @old_pid1
    @p2_.pid.should == @old_pid2
    @p3_.pid.should == @old_pid3
    
    @p1_.state_name.should == :up
  end

end