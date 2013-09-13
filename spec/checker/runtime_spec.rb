require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Checker::Runtime" do

  subject do
    Eye::Checker.create(123, {:type => :runtime, :every => 5.seconds, :times => 1, :below => 10.minutes})
  end

  it "get_value" do
    mock(Eye::SystemResources).start_time(123){ 65 }
    subject.get_value.should == Time.now.to_i - 65
  end

  it "good" do
    stub(subject).get_value{ 5.minutes }
    subject.check.should == true

    stub(subject).get_value{ 20.minutes }
    subject.check.should == false
  end
end
