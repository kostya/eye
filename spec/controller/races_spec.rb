require File.dirname(__FILE__) + '/../spec_helper'

describe "Some crazy situations on load config" do

  before :each do
    start_controller do
      @controller.load_erb(fixture("dsl/integration.erb"))
    end
  end

  after :each do
    stop_controller

    File.delete(File.join(C.sample_dir, "lock1.lock")) rescue nil
    File.delete(File.join(C.sample_dir, "lock2.lock")) rescue nil
  end

  it "load another config, with same processes but changed names" do
    @controller.load_erb(fixture("dsl/integration2.erb"))

    sleep 10

    # @p1, @p2 recreates
    # @p3 the same

    procs = @controller.all_processes
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