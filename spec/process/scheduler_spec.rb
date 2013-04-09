require File.dirname(__FILE__) + '/../spec_helper'

class Eye::Process
  attr_reader :test1, :test2, :test3, :test1_call

  def scheduler_test1(a)
    sleep 0.3
    @test1_call ||= 0
    @test1_call += 1
    @test1 = a
  end

  def scheduler_test2(a, b)
    sleep 0.6
    @test2 = [a, b]
  end

  def scheduler_test3(*args)    
    @test3 = args
  end

  public :scheduler

end

describe "Scheduler" do
  before :each do
    @process = process C.p1
  end

  it "should schedule action" do
    @process.test1.should == nil
    @process.schedule :scheduler_test1, 1
    sleep 0.1
    @process.current_scheduled_command.should == :scheduler_test1
    @process.test1.should == nil
    sleep 0.4
    @process.test1.should == 1
    @process.current_scheduled_command.should == nil
  end

  it "should one after another" do
    @process.test1.should == nil
    @process.test2.should == nil

    @process.schedule :scheduler_test1, 1
    @process.schedule :scheduler_test2, 1, 2

    sleep 0.4 
    @process.test1.should == 1
    @process.test2.should == nil

    sleep 0.6
    @process.test1.should == 1
    @process.test2.should == [1, 2]
  end

  it "should one after another2" do
    @process.test1.should == nil
    @process.test2.should == nil

    @process.schedule :scheduler_test2, 1, 2
    @process.schedule :scheduler_test1, 1
    
    sleep 0.4 
    @process.test1.should == nil
    @process.test2.should == nil

    sleep 0.3
    @process.test1.should == nil
    @process.test2.should == [1, 2]

    sleep 0.3
    @process.test1.should == 1
    @process.test2.should == [1, 2]
  end

  it "should not scheduler dublicates" do
    @process.schedule :scheduler_test1, 1
    @process.schedule :scheduler_test1, 1
    @process.schedule :scheduler_test1, 1

    sleep 1
    @process.test1_call.should == 2
  end

  it "should scheduler dublicates by with different params" do
    @process.schedule :scheduler_test1, 1
    @process.schedule :scheduler_test1, 2
    @process.schedule :scheduler_test1, 3

    sleep 1
    @process.test1_call.should == 3
  end

  it "should terminate when actor die" do
    scheduler = @process.scheduler
    @process.alive?.should == true
    scheduler.alive?.should == true
    @process.terminate
    @process.alive?.should == false
    scheduler.alive?.should == false
  end

  it "should terminate even with tasks" do
    scheduler = @process.scheduler
    @process.schedule :scheduler_test1, 1
    @process.schedule :scheduler_test1, 1
    @process.schedule :scheduler_test1, 1

    @process.terminate
    scheduler.alive?.should == false
  end

  it "when scheduling terminate of the parent actor" do
    scheduler = @process.scheduler
    @process.schedule :terminate
    @process.schedule(:scheduler_test1, 1) rescue nil

    sleep 0.2
    @process.alive?.should == false
    scheduler.alive?.should == false
  end

  it "schedule unexisted method should not raise and break anything" do
    scheduler = @process.scheduler
    @process.schedule :hahhaha
    sleep 0.2
    @process.alive?.should == true
    scheduler.alive?.should == true
  end

  describe "reasons" do
    it "1 param without reason" do
      @process.schedule :scheduler_test3, 1
      sleep 0.1
      @process.last_scheduled_command.should == :scheduler_test3
      @process.last_scheduled_reason.should == nil
      @process.test3.should == [1]
    end

    it "1 param with reason" do
      @process.schedule :scheduler_test3, 1, "reason"
      sleep 0.1
      @process.last_scheduled_command.should == :scheduler_test3
      @process.last_scheduled_reason.should == 'reason'
      @process.test3.should == [1]
    end

    it "many params with reason" do
      @process.schedule :scheduler_test3, 1, :bla, 3, "reason"
      sleep 0.1
      @process.last_scheduled_command.should == :scheduler_test3
      @process.last_scheduled_reason.should == 'reason'
      @process.test3.should == [1, :bla, 3]
    end
  end

  describe "schedule_in" do
    it "should schedule to future" do
      @process.schedule_in(1.second, :scheduler_test3, 1, 2, 3)
      sleep 0.5
      @process.test3.should == nil
      sleep 0.6
      @process.test3.should == [1,2,3]
    end
  end
end