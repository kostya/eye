require File.dirname(__FILE__) + '/../spec_helper'

class TestActor
  include Celluloid

  attr_reader :m

  def initialize
    @m = []
  end

  def a(tm = 0.1)
    @m << :a
    sleep tm
  end

  def b(tm = 0.1)
    @m << :b
    sleep tm
  end

  def c(tm = 0.1)
    @m << :c
    sleep tm
  end
end

describe "Eye::Utils::CelluloidChain" do
  before :each do
    @t = TestActor.new
    @c = Eye::Utils::CelluloidChain.new(@t)    
  end

  it "should chain" do
    @c.add :a, 0.5
    @c.add :b, 0.3
    @c.add :c, 0.1

    sleep 1

    @t.m.should == [:a, :b, :c]
  end

  it "should chain2" do
    @c.add :c, 0.1
    sleep 0.2

    @c.add :a, 0.5
    @c.add :b, 0.3

    sleep 1

    @t.m.should == [:c, :a, :b]
  end

  it "should remove dups" do
    @c.add :a
    @c.add :b
    @c.add :b
    @c.add :c
    @c.add_wo_dups :c

    sleep 1
    @t.m.should == [:a, :b, :b, :c]
  end

  it "should remove dups" do
    @c.add_wo_dups :a
    @c.add_wo_dups :b
    @c.add_wo_dups :b
    @c.add_wo_dups :c
    @c.add_wo_dups :c
    @c.add_wo_dups :a
    @c.add_wo_dups :c
    @c.add_wo_dups :c

    sleep 2
    @t.m.should == [:a, :b, :c, :a, :c]
  end

  it "#clear_pending_list" do
    10.times{ @c.add :a }
    sleep 0.5
    @c.clear_pending_list
    sleep 0.5
    @t.m.size.should < 6
  end

end