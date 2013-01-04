require File.dirname(__FILE__) + '/../spec_helper'

describe "StopOnRemove behaviour" do
  before :each do
    @c = Eye::Controller.new
    @c.load(fixture("dsl/integration_sor.eye"))
    @processes = @c.all_processes
    @p1 = @processes.detect{|c| c.name == 'sample1'}
    @p2 = @processes.detect{|c| c.name == 'sample2'}
    @p3 = @processes.detect{|c| c.name == 'forking'}
    @samples = @c.all_groups.detect{|c| c.name == 'samples'}
    sleep 10 # to ensure that all processes started

    @processes.size.should == 3
    @processes.map{|c| c.state_name}.uniq.should == [:up]
    @childs = @p3.childs.keys rescue []

    @old_pid1 = @p1.pid
    @old_pid2 = @p2.pid
    @old_pid3 = @p3.pid
  end

  after :each do
    @processes = @c.all_processes
    @processes.each do |p|
      p.schedule(:stop) if p.alive?
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

  it "remove process => stop process" do
    @c.send_command(:remove, "sample1")
    sleep 7 # while 

    @c.all_processes.map(&:name).sort.should == %w{forking sample2}
    @c.all_groups.map(&:name).sort.should == %w{__default__ samples}

    Eye::System.pid_alive?(@old_pid1).should == false
    Eye::System.pid_alive?(@old_pid2).should == true
    Eye::System.pid_alive?(@old_pid3).should == true

    sleep 0.5
    Eye::System.pid_alive?(@old_pid1).should == false
  end

  it "remove application => stop group proceses" do
    @c.send_command(:remove, "samples").should == "[samples]"
    sleep 7 # while 

    @c.all_processes.should == [@p3]
    @c.all_groups.map(&:name).should == ['__default__']

    Eye::System.pid_alive?(@old_pid1).should == false
    Eye::System.pid_alive?(@old_pid2).should == false
    Eye::System.pid_alive?(@old_pid3).should == true

    sleep 0.5
    Eye::System.pid_alive?(@old_pid1).should == false

    # noone up this
    sleep 2
    Eye::System.pid_alive?(@old_pid1).should == false    
  end

  it "remove application => stop all proceses" do
    @c.send_command(:remove, "int")
    sleep 7 # while 

    @c.all_processes.should == []
    @c.all_groups.should == []
    @c.applications.should == []

    Eye::System.pid_alive?(@old_pid1).should == false
    Eye::System.pid_alive?(@old_pid2).should == false
    Eye::System.pid_alive?(@old_pid3).should == false

    sleep 0.5
    Eye::System.pid_alive?(@old_pid1).should == false

    actors = Celluloid::Actor.all.map(&:class)
    actors.should_not include(Celluloid::Chain)
    actors.should_not include(Eye::Process)
    actors.should_not include(Eye::Group)
    actors.should_not include(Eye::Application)
    actors.should_not include(Eye::Checker::Memory)
  end

  it "load config when 1 process removed, it should stopped" do
    @c.load(fixture("dsl/integration_sor2.eye"))
    sleep 10

    procs = @c.all_processes 
    @p1_ = procs.detect{|c| c.name == 'sample1'}
    @p2_ = procs.detect{|c| c.name == 'sample2'}
    @p3_ = procs.detect{|c| c.name == 'sample3'}

    @p1_.object_id.should == @p1.object_id
    @p2_.object_id.should == @p2.object_id
    @p3_.state_name.should == :up

    @p1_.pid.should == @old_pid1
    @p2_.pid.should == @old_pid2

    Eye::System.pid_alive?(@old_pid1).should == true
    Eye::System.pid_alive?(@old_pid2).should == true
    Eye::System.pid_alive?(@old_pid3).should == false

    @p3.alive?.should == false
    @c.all_processes.map{|c| c.name}.sort.should == %w{sample1 sample2 sample3}
  end

  it "load another config, with same processes but changed names" do
    @c.load(fixture("dsl/integration_sor3.eye"))
    sleep 15
    
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
    
    @p1_.pid.should_not == @old_pid1
    @p2_.pid.should_not == @old_pid2
    @p3_.pid.should == @old_pid3
    
    @p1_.state_name.should == :up
    @p2_.state_name.should == :up
    @p3_.state_name.should == :up

    Eye::System.pid_alive?(@old_pid1).should == false
    Eye::System.pid_alive?(@old_pid2).should == false
    Eye::System.pid_alive?(@old_pid3).should == true

    Eye::System.pid_alive?(@p1_.pid).should == true
    Eye::System.pid_alive?(@p2_.pid).should == true
  end

end