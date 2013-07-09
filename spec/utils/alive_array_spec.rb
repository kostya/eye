require File.dirname(__FILE__) + '/../spec_helper'

class AliveArrayActor
  include Celluloid

  attr_reader :name

  def initialize(name)
    @name = name
  end
end

describe "Eye::Utils::AliveArray" do

  it "act like array" do
    a = Eye::Utils::AliveArray.new([1,2,3])
    a.size.should == 3
    a.empty?.should == false
    a << 4
    a.pure.should == [1,2,3,4]
  end

  it "alive actions" do
    a = AliveArrayActor.new('a')
    b = AliveArrayActor.new('b'); b.terminate
    c = AliveArrayActor.new('c')

    l = Eye::Utils::AliveArray.new([a,b,c])
    l.size.should == 3
    l.map{|a| a.name}.sort.should == %w{a c}

    l.detect{|c| c.name == 'a'}.name.should == 'a'
    l.detect{|c| c.name == 'b'}.should == nil

    l.any?{|c| c.name == 'a'}.should == true
    l.any?{|c| c.name == 'b'}.should == false

    l.include?(a).should == true
    l.include?(b).should == false

    l.sort_by(&:name).class.should == Eye::Utils::AliveArray
    l.sort_by(&:name).pure.should == [a, c]

    l.to_a.map{|c| c.name}.sort.should == %w{a c}

    a.terminate
    c.terminate
  end
end
