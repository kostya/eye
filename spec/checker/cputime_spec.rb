require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Checker::Cputime" do

  subject do
    Eye::Checker.create(123, {:type => :cputime, :every => 5.seconds, :times => 1, :below => 10.minutes})
  end

  it "get_value" do
    mock(Eye::SystemResources).cputime(123){ 65 }
    subject.get_value.should == 65
  end

  it "good" do
    stub(subject).get_value{ 5.minutes }
    subject.check.should == true

    stub(subject).get_value{ 20.minutes }
    subject.check.should == false
  end
end
