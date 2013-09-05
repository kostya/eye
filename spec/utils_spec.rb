require File.dirname(__FILE__) + '/spec_helper'

describe "Eye::Utils" do
  it "human_time" do
    s = Eye::Utils.human_time(Time.now.to_i)
    s.size.should == 5
    s.should include(':')

    s = Eye::Utils.human_time(1377978030)
    s.should == 'Aug31'
  end
end
