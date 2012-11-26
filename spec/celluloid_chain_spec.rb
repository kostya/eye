# -*- encoding : utf-8 -*-
require File.dirname(__FILE__) + '/spec_helper'

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

describe "Celluloid::Chain" do
  before :each do
    @t = TestActor.new
    @c = Celluloid::Chain.new(@t)    
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
    @c.add_no_dup :c

    sleep 1
    @t.m.should == [:a, :b, :b, :c]
  end

  it "should remove dups" do
    @c.add_no_dup :a
    @c.add_no_dup :b
    @c.add_no_dup :b
    @c.add_no_dup :c
    @c.add_no_dup :c
    @c.add_no_dup :a
    @c.add_no_dup :c
    @c.add_no_dup :c

    sleep 2
    @t.m.should == [:a, :b, :c, :a, :c]
  end


end