require File.dirname(__FILE__) + '/../spec_helper'

def chctime(cfg = {})
  Eye::Checker.create(nil, {:type => :ctime, :every => 5.seconds, 
        :file => $logger_path, :times => 1}.merge(cfg))
end

describe "Eye::Checker::FileCTime" do

  describe "" do
    subject{ chctime }

    it "get_value" do
      subject.get_value.should == File.ctime($logger_path)
    end

    it "not good if size equal prevous" do
      stub(subject).get_value{ Time.parse('00:00:01') }
      subject.check.should == true

      stub(subject).get_value{ Time.parse('00:00:01') }
      subject.check.should == false
    end

    it "good when little different with previous" do
      stub(subject).get_value{ Time.parse('00:00:01') }
      subject.check.should == true

      stub(subject).get_value{ Time.parse('00:00:02') }
      subject.check.should == true
    end
  end

end