require File.dirname(__FILE__) + '/../spec_helper'

describe "Some crazey situations" do

  before :each do
    @c = Eye::Controller.new
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

    File.delete(File.join(C.sample_dir, "lock1.lock")) rescue nil
    File.delete(File.join(C.sample_dir, "lock2.lock")) rescue nil
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