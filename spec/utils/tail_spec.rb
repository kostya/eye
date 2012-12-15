# -*- encoding : utf-8 -*-
require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Utils::Tail" do
  subject{ Eye::Utils::Tail.new(5) }

  it "should rotate" do
    subject << 1
    subject << 2
    subject << 3
    subject.push 4
    subject.should == [1,2,3,4]

    subject << 5
    subject.should == [1,2,3,4,5]

    subject << 6
    subject.should == [2,3,4,5,6]
  end

end
