require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Dsl::MHash" do
  subject{ Eye::Dsl::MHash.new }
  
  it "should work" do
    subject[1][2][3] = 4
    subject.pure.should == {1 => {2 => {3 => 4}}}
  end
end