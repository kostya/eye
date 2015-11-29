require File.dirname(__FILE__) + '/../spec_helper'

class TestEnumerable
  include Celluloid

  attr_reader :sum

  def initialize
    @sum = 0
  end

  def bla(x, s)
    sleep(x)
    @sum += x
    s.done!
  end

  def group(x, s)
    s.wait_group do |gr|
      x.times do |i|
        async.bla(i + 1, gr.child)
      end
    end
  end
end

describe "Syncer" do

  before(:each) do
    @actor = TestEnumerable.new
  end

  after(:each) do
    @actor.terminate
  end

  describe "wait" do
    it "ok" do
      should_spend(1, 0.7) do
        res = Eye::Utils::Syncer.with(2) do |s|
          @actor.async.bla(1, s)
        end

        res.should == :ok
      end
    end

    it "timeouted" do
      should_spend(0.5) do
        res = Eye::Utils::Syncer.with(0.5) do |s|
          @actor.async.bla(1, s)
        end
        res.should == :timeouted
      end
    end
  end

  describe "group" do
    it "tree" do
      should_spend(0.1) do
        s = Eye::Utils::Syncer.new
        @actor.async.bla(0.1, s)
        s.wait.should == :ok
      end
    end

    it "tree" do
      should_spend(0.1) do
        Eye::Utils::Syncer.new.wait_group do |gr|
          @actor.async.bla(0.1, gr.child)
        end.should == :ok
      end
    end

    it "ok" do
      should_spend(2) do
        Eye::Utils::Syncer.new(2.5).wait_group do |gr|
          @actor.async.bla(1, gr.child)
          @actor.async.bla(2, gr.child)
          @actor.async.bla(1.5, gr.child)
        end.should == :ok
      end
      @actor.sum.should == 4.5
    end

    it "timeouted" do
      should_spend(0.5) do
        Eye::Utils::Syncer.new(0.5).wait_group do |gr|
          @actor.async.bla(0.3, gr.child)
          @actor.async.bla(3, gr.child)
          @actor.async.bla(4, gr.child)
          @actor.async.bla(5, gr.child)
        end.should == :timeouted
      end
      @actor.sum.should == 0.3
    end
  end

  describe "deep group" do
    it "ok" do
      should_spend(3) do
        s = Eye::Utils::Syncer.new(3.1)
        @actor.async.group(3, s)
        s.wait.should == :ok
      end
      @actor.sum.should == 6
    end

    it "ok" do
      should_spend(3) do
        Eye::Utils::Syncer.new(5).wait_group do |gr|
          @actor.async.group(1, gr.child)
          @actor.async.group(2, gr.child)
          @actor.async.group(3, gr.child)
        end.should == :ok
      end

      @actor.sum.should == 10
    end

    it "timeouted" do
      should_spend(1.5, 0.1) do
        Eye::Utils::Syncer.new(1.5).wait_group do |gr|
          @actor.async.group(1, gr.child)
          @actor.async.group(2, gr.child)
          @actor.async.group(3, gr.child)
        end.should == :timeouted
      end

      @actor.sum.should == 3
    end
  end

end
