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

  attr_reader :m

  def a(tm = 0.1)
    @m ||= []
    @m << :a
    sleep tm
  end

  def b(tm = 0.1)
    @m ||= []
    @m << :b
    sleep tm
  end

  def cu(tm = 0.1)
    @m ||= []
    @m << :cu
    sleep tm
  end

end

describe "Scheduler" do
  before :each do
    @process = process C.p1
  end

  it "should schedule action" do
    @process.test1.should == nil
    @process.schedule :scheduler_test1, 1
    sleep 0.1
    @process.scheduler_current_command.should == :scheduler_test1
    @process.test1.should == nil
    sleep 0.4
    @process.test1.should == 1
    @process.scheduler_current_command.should == nil
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

  xit "should not scheduler duplicates" do
    @process.schedule :scheduler_test1, 1
    @process.schedule :scheduler_test1, 1
    @process.schedule :scheduler_test1, 1

    sleep 1
    @process.test1_call.should == 2
  end

  it "should scheduler duplicates by with different params" do
    @process.schedule :scheduler_test1, 1
    @process.schedule :scheduler_test1, 2
    @process.schedule :scheduler_test1, 3

    sleep 1
    @process.test1_call.should == 3
  end

  it "should terminate when actor die" do
    @process.alive?.should == true
    @process.terminate
    @process.alive?.should == false
  end

  it "should terminate even with tasks" do
    @process.schedule :scheduler_test1, 1
    @process.schedule :scheduler_test1, 1
    @process.schedule :scheduler_test1, 1

    @process.terminate
  end

  it "when scheduling terminate of the parent actor" do
    @process.schedule :terminate
    @process.schedule(:scheduler_test1, 1) rescue nil

    sleep 0.4
    @process.alive?.should == false
  end

  it "schedule unexisted method should not raise and break anything" do
    @process.schedule :hahhaha
    sleep 0.2
    @process.alive?.should == true
  end

  describe "reasons" do
    it "1 param without reason" do
      @process.schedule :scheduler_test3, 1
      sleep 0.1
      @process.scheduler_last_command.should == :scheduler_test3
      @process.scheduler_last_reason.should == nil
      @process.test3.should == [1]
    end

    it "1 param with reason" do
      @process.schedule command: :scheduler_test3, args: [1], reason: "reason"
      sleep 0.1
      @process.scheduler_last_command.should == :scheduler_test3
      @process.scheduler_last_reason.should == 'reason'
      @process.test3.should == [1]
    end

    it "many params with reason" do
      @process.schedule command: :scheduler_test3, args: [1, :bla, 3], reason: "reason"
      sleep 0.1
      @process.scheduler_last_command.should == :scheduler_test3
      @process.scheduler_last_reason.should == 'reason'
      @process.test3.should == [1, :bla, 3]
    end

    it "save history" do
      @process.schedule command: :scheduler_test3, args: [1, :bla, 3], reason: "reason"
      sleep 0.1
      h = @process.scheduler_history
      h.size.should == 1
      h = h[0]
      h[:state].should == :scheduler_test3
      h[:reason].to_s.should == "reason"
    end
  end

  describe "signals" do
    it "work" do
      should_spend(0.3) do
        c1 = Celluloid::Condition.new
        @process.schedule command: :scheduler_test1, args: [1], reason: "reason", signal: c1
        c1.wait
      end
      @process.test1.should == 1
    end

    it "work with combinations" do
      should_spend(0.9) do
        c1 = Celluloid::Condition.new
        c2 = Celluloid::Condition.new
        @process.schedule command: :scheduler_test1, args: [1], reason: "reason", signal: c1
        @process.schedule command: :scheduler_test2, args: [1, 2], reason: "reason", signal: c2
        c1.wait
        c2.wait
      end
      @process.test1.should == 1
      @process.test2.should == [1, 2]
    end
  end

  describe "schedule_in" do
    it "should schedule to future" do
      @process.schedule(in: 1.second, command: :scheduler_test3, args: [1, 2, 3])
      sleep 0.5
      @process.test3.should == nil
      sleep 0.7
      @process.test3.should == [1,2,3]
    end
  end

  describe "when scheduler_freeze not accept new commands" do
    it "should schedule to future" do
      @process.schedule(:scheduler_test3, 1, 2, 3)
      sleep 0.01
      @process.test3.should == [1, 2, 3]

      @process.scheduler_freeze = true
      @process.schedule(:scheduler_test3, 5)
      @process.schedule(:scheduler_test3, 6)
      sleep 0.1
      @process.test3.should == [1, 2, 3]

      @process.scheduler_freeze = false
      @process.schedule(:scheduler_test3, 7)
      sleep 0.1
      @process.test3.should == [7]
    end
  end

  describe "schedule block" do
    it "schedule block" do
      @process.schedule(command: :instance_exec, block: -> { @test3 = [1, 2] })
      sleep 0.1
      @process.test3.should == [1, 2]
    end

    it "not crashing on exception" do
      @process.schedule(:instance_exec, block: -> { 1 + "bla" })
      sleep 0.1
      @process.alive?.should be_true
    end
  end

  describe "Calls test" do
    before :each do
      @t = @process
    end

    it "should chain" do
      @t.scheduler_add command: :a, args: [0.5]
      @t.scheduler_add command: :b, args: [0.3]
      @t.scheduler_add command: :cu, args: [0.1]

      sleep 1

      @t.m.should == [:a, :b, :cu]
    end

    it "should chain2" do
      @t.scheduler_add command: :cu, args: [0.1]
      sleep 0.2

      @t.scheduler_add command: :a, args: [0.5]
      @t.scheduler_add command: :b, args: [0.3]

      sleep 1

      @t.m.should == [:cu, :a, :b]
    end

    xit "should remove dups" do
      @t.scheduler_add :a
      @t.scheduler_add :b
      @t.scheduler_add :b
      @t.scheduler_add :cu
      @t.scheduler_add_wo_dups :cu

      sleep 1
      @t.m.should == [:a, :b, :b, :cu]
    end

    xit "should remove dups" do
      @t.scheduler_add_wo_dups :a
      @t.scheduler_add_wo_dups :b
      @t.scheduler_add_wo_dups :b
      @t.scheduler_add_wo_dups :cu
      @t.scheduler_add_wo_dups :cu
      @t.scheduler_add_wo_dups :a
      @t.scheduler_add_wo_dups :cu
      @t.scheduler_add_wo_dups :cu

      sleep 2
      @t.m.should == [:a, :b, :cu, :a, :cu]
    end

    xit "should remove dups and current" do
      @t.scheduler_add_wo_dups_current :a, 0.6
      sleep 0.3
      @t.scheduler_add_wo_dups_current :a, 0.6
      @t.scheduler_add_wo_dups_current :b

      sleep 0.4
      @t.m.should == [:a, :b]
    end

    it "#clear_pending_list" do
      10.times{ @t.scheduler_add command: :a }
      sleep 0.5
      @t.scheduler_clear_pending_list
      sleep 0.5
      @t.m.size.should <= 6
    end
  end
end
