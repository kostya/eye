# -*- encoding : utf-8 -*-
require File.dirname(__FILE__) + '/spec_helper'

describe "Eye::Tail" do
  before :each do
    @t = Eye::Tail.new(5)
  end

  it "should rotate" do
    @t << 1
    @t << 2
    @t << 3
    @t.push 4
    @t.should == [1,2,3,4]

    @t << 5
    @t.should == [1,2,3,4,5]

    @t << 6
    @t.should == [2,3,4,5,6]
  end

end
