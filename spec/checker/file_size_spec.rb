require File.dirname(__FILE__) + '/../spec_helper'

def chfsize(cfg = {})
  Eye::Checker.create(nil, {:type => :fsize, :every => 5.seconds,
        :file => $logger_path, :times => 1}.merge(cfg))
end

describe "Eye::Checker::FileSize" do

  describe "" do
    subject{ chfsize }

    it "get_value" do
      subject.get_value.should be_within(10).of(File.size($logger_path))
    end

    it "not good if size equal prevous" do
      stub(subject).get_value{1001}
      subject.check.should == true

      stub(subject).get_value{1001}
      subject.check.should == false
    end

    it "good when little different with previous" do
      stub(subject).get_value{1001}
      subject.check.should == true

      stub(subject).get_value{1002}
      subject.check.should == true
    end
  end

  describe "below" do
    subject{ chfsize(:below => 10) }

    it "good" do
      stub(subject).get_value{1001}
      subject.check.should == true

      stub(subject).get_value{1005}
      subject.check.should == true
    end

    it "bad" do
      stub(subject).get_value{1001}
      subject.check.should == true

      stub(subject).get_value{1015}
      subject.check.should == false
    end

  end

  describe "above" do
    subject{ chfsize(:above => 10) }

    it "good" do
      stub(subject).get_value{1001}
      subject.check.should == true

      stub(subject).get_value{1005}
      subject.check.should == false
    end

    it "bad" do
      stub(subject).get_value{1001}
      subject.check.should == true

      stub(subject).get_value{1015}
      subject.check.should == true
    end

  end


  describe "above and below" do
    subject{ chfsize(:above => 10, :below => 30) }

    it "bad" do
      stub(subject).get_value{1001}
      subject.check.should == true

      stub(subject).get_value{1005}
      subject.check.should == false
    end

    it "good" do
      stub(subject).get_value{1001}
      subject.check.should == true

      stub(subject).get_value{1021}
      subject.check.should == true
    end

    it "bad" do
      stub(subject).get_value{1001}
      subject.check.should == true

      stub(subject).get_value{1045}
      subject.check.should == false
    end

  end


end