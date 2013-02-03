# -*- encoding : utf-8 -*-
require File.dirname(__FILE__) + '/../spec_helper'

class AliveArrayActor
  include Celluloid

  attr_reader :name

  def initialize(name)
    @name = name
  end
end

describe "AliveArray" do

  it "act like array" do
    a = AliveArray.new([1,2,3])
    a.size.should == 3
    a.empty?.should == false
    a << 4
    a.to_a.should == [1,2,3,4]
  end

  it "alive actions" do
    a = AliveArrayActor.new('a')
    b = AliveArrayActor.new('b'); b.terminate
    c = AliveArrayActor.new('c')
    
    l = AliveArray.new([a,b,c])
    l.size.should == 3
    l.map{|a| a.name}.sort.should == %w{a c}

    l.detect{|c| c.name == 'a'}.name.should == 'a'
    l.detect{|c| c.name == 'b'}.should == nil

    l.any?{|c| c.name == 'a'}.should == true
    l.any?{|c| c.name == 'b'}.should == false

    l.include?(a).should == true
    l.include?(b).should == false

    a.terminate
    c.terminate
  end
end
