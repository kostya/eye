require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Checker::FileTouched" do

  subject do
    Eye::Checker.create(123, {:type => :file_touched, :every => 5.seconds, :times => 1, :file => "1"})
  end

  it "get_value" do
    mock(File).exist?("1"){ true }
    subject.get_value.should == true

    mock(File).exist?("1"){ false }
    subject.get_value.should == false
  end

  it "good" do
    mock(File).exist?("1"){ true }
    subject.check.should == false

    mock(File).exist?("1"){ false }
    subject.check.should == true
  end
end
