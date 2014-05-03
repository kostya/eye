require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Process::Data" do
  subject { process(C.p1) }

  it "shell_string" do
    subject.shell_string(false).should == 'ENV1=SUPER ruby sample.rb &'
  end
end
