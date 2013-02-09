require File.dirname(__FILE__) + '/../spec_helper'

def chsock(cfg = {})
  Eye::Checker.create(nil, {:type => :socket, :every => 5.seconds, 
        :times => 1, :addr => "tcp://127.0.0.1:3000", :send_data => "ping", 
        :expect_data => /pong/, :timeout => 2}.merge(cfg))
end

describe "Intergration" do
  %w[ tcp://127.0.0.1:33231 unix:/tmp/em_test_sock_spec].each do |addr|
    describe "real socket: #{addr}" do
      before :each do
        start_ok_process(C.p4)
      end

      it "good answer w" do
        c = chsock(:addr => addr)
        c.get_value.should == {:result => 'pong'}
        c.check.should == true

        c = chsock(:addr => addr, :expect_data => "pong") # string result ok too
        c.check.should == true
      end

      it "timeouted" do
        c = chsock(:addr => addr, :send_data => "timeout")
        c.get_value.should == {:exception => :timeout}
        c.check.should == false
      end

      it "bad answer" do
        c = chsock(:addr => addr, :send_data => "bad")
        c.get_value.should == {:result => 'what'}
        c.check.should == false
      end

      it "socket not found" do
        @process.stop
        c = chsock(:addr => addr.chop)
        if addr =~ /tcp/
          c.get_value.should == {:exception => "Connection refused - connect(2)"}
        else
          c.get_value.should == {:exception => "No such file or directory - /tmp/em_test_sock_spe"}
        end
        c.check.should == false
      end

      it "check responding without send_data" do
        c = chsock(:addr => addr, :send_data => nil, :expect_data => nil)
        c.get_value.should == {:result => :listen}
        c.check.should == true
      end

      it "check responding without send_data" do
        c = chsock(:addr => addr.chop, :send_data => nil, :expect_data => nil)
        if addr =~ /tcp/
          c.get_value.should == {:exception => "Connection refused - connect(2)"}
        else
          c.get_value.should == {:exception => "No such file or directory - /tmp/em_test_sock_spe"}
        end
        c.check.should == false
      end
    end

  end
end