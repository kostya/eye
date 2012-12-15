require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Utils::MHash" do
  subject{ Eye::Utils::MHash.new }
  
  it "should work" do
    subject[1][2][3] = 4
    subject.pure.should == {1 => {2 => {3 => 4}}}
  end
end