require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::ChildProcess" do

  before :each do
    @pid = Eye::System.daemonize(C.p1[:start_command], C.p1)
    Eye::System.pid_alive?(@pid).should == true
    sleep 0.5
  end

  it "some process was declared by my child" do
    @process = Eye::ChildProcess.new(@pid, $logger, {})
    @process.pid.should == @pid

    @process.watchers.keys.should == []
  end

  describe "restart" do

    it "kill by default command" do
      @process = Eye::ChildProcess.new(@pid, $logger, {})
      @process.queue :restart

      sleep 0.5
      Eye::System.pid_alive?(@pid).should == false      
    end  

    it "kill by stop command" do
      @process = Eye::ChildProcess.new(@pid, $logger, {:stop_command => "kill -9 {{PID}}"})
      @process.queue :restart

      sleep 0.5
      Eye::System.pid_alive?(@pid).should == false
    end

    it "try to snd URS1" do
      @process = Eye::ChildProcess.new(@pid, $logger, {:stop_command => "kill -USR1 {{PID}}"})
      @process.queue :restart

      sleep 0.5
      Eye::System.pid_alive?(@pid).should == true
    end
  end

end

