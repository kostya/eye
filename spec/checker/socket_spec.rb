require File.dirname(__FILE__) + '/../spec_helper'

def chsock(cfg = {})
  Eye::Checker.create(nil, {:type => :socket, :every => 5.seconds,
        :times => 1, :addr => "tcp://127.0.0.1:#{C.p4_ports[0]}", :send_data => "ping",
        :expect_data => /pong/, :timeout => 2}.merge(cfg))
end

def chsockb(cfg = {})
  Eye::Checker.create(nil, {:type => :socket, :every => 5.seconds,
        :times => 1, :addr => "tcp://127.0.0.1:#{C.p4_ports[1]}", :protocol => :em_object, :send_data => {},
        :expect_data => /pong/, :timeout => 2}.merge(cfg))
end

describe "Socket Checker" do
  after :each do
    FileUtils.rm(C.p4_sock) rescue nil
  end

  ["tcp://127.0.0.1:#{C.p4_ports[0]}", "unix:#{C.p4_sock}"].each do |addr|
    describe "socket: '#{addr}'" do
      before :each do
        start_ok_process(C.p4)
      end

      it "good answer" do
        c = chsock(:addr => addr)
        c.get_value.should == {:result => 'pong'}
        c.check.should == true

        c = chsock(:addr => addr, :expect_data => "pong") # string result ok too
        c.check.should == true
      end

      it "timeouted" do
        c = chsock(:addr => addr, :send_data => "timeout")
        c.get_value.should == {:exception => "ReadTimeout<2.0>"}
        c.check.should == false
      end

      it "bad answer" do
        c = chsock(:addr => addr, :send_data => "bad")
        c.get_value.should == {:result => 'what'}
        c.check.should == false

        c = chsock(:addr => addr, :send_data => "bad", :expect_data => "pong") # string result bad too
        c.check.should == false
      end

      it "socket not found" do
        @process.stop
        c = chsock(:addr => addr + "111")
        if addr =~ /tcp/
          c.get_value[:exception].should include("Error<")
        else
          c.get_value[:exception].should include("No such file or directory")
        end
        c.check.should == false
      end

      it "check responding without send_data" do
        c = chsock(:addr => addr, :send_data => nil, :expect_data => nil)
        c.get_value.should == {:result => :listen}
        c.check.should == true
      end

      it "check responding without send_data" do
        c = chsock(:addr => addr + "111", :send_data => nil, :expect_data => nil)
        if addr =~ /tcp/
          c.get_value[:exception].should include("Error<")
        else
          c.get_value[:exception].should include("No such file or directory")
        end
        c.check.should == false
      end
    end

    describe "raw protocol '#{addr}'" do
      before :each do
        start_ok_process(C.p4)
      end

      it "good answer" do
        c = chsock(:addr => addr, :send_data => 'raw', :expect_data => "raw_ans", :timeout => 0.5, :protocol => :raw)
        c.get_value.should == {:result => 'raw_ans'}
        c.check.should == true
      end

      it "timeout when using without :raw" do
        c = chsock(:addr => addr, :send_data => 'raw', :expect_data => "raw_ans", :timeout => 0.5)
        c.get_value.should == {:exception => "ReadTimeout<0.5>"}
        c.check.should == false
      end
    end
  end

  describe "em object protocol" do
    before :each do
      start_ok_process(C.p4)
    end

    it "good answer" do
      c = chsockb(:send_data => {:command => 'ping'}, :expect_data => 'pong')
      c.get_value.should == {:result => 'pong'}
      c.check.should == true

      c = chsockb(:send_data => {:command => 'ping'}, :expect_data => /pong/)
      c.check.should == true

      c = chsockb(:send_data => {:command => 'ping'}, :expect_data => lambda{|r| r == 'pong'})
      c.check.should == true
    end

    it "should correctly get big message" do
      c = chsockb(:send_data => {:command => 'big'})
      res = c.get_value[:result]
      res.size.should == 9_999_999
    end

    it "when raised in proc, good? == false" do
      c = chsockb(:send_data => {:command => 'ping'}, :expect_data => lambda{|r| raise 'haha'})
      c.check.should == false
    end

    it "bad answer" do
      c = chsockb(:send_data => {:command => 'bad'}, :expect_data => 'pong')
      c.get_value.should == {:result => 'what'}
      c.check.should == false

      c = chsockb(:send_data => {:command => 'bad'}, :expect_data => /pong/)
      c.check.should == false

      c = chsockb(:send_data => {:command => 'bad'}, :expect_data => lambda{|r| r == 'pong'})
      c.check.should == false
    end
  end
end