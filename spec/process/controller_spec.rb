require File.dirname(__FILE__) + '/../spec_helper'

describe "Process Controller" do

  describe "monitor" do
    it "monitor should call start, as the auto_start is default" do
      start_ok_process

      @process.unmonitor
      @process.state_name.should == :unmonitored
      
      mock(@process).start
      @process.monitor
    end
    
  end

  describe "unmonitor" do    
    [C.p1, C.p2].each do |cfg|
      it "should just forget about any process #{cfg[:name]}" do
        start_ok_process
        old_pid = @process.pid

        @process.unmonitor

        Eye::System.pid_alive?(old_pid).should == true

        @process.pid.should == nil
        @process.state_name.should == :unmonitored

        @process.watchers.keys.should == []
        @process.load_pid_from_file.should == old_pid

        sleep 1

        # event if something now kill the process
        die_process!(old_pid)

        # nothing try to up it
        sleep 5

        @process.state_name.should == :unmonitored
        @process.load_pid_from_file.should == old_pid
      end
    end
  end

  describe "remove" do
    it "remove monitoring, not kill process" do
      start_ok_process
      old_pid = @process.pid

      @process.remove
      Eye::System.pid_alive?(old_pid).should == true

      @process = nil
    end
  end

  describe "stop" do
    it "stop kill process, and moving to unmonitored" do
      start_ok_process

      @process.stop

      Eye::System.pid_alive?(@pid).should == false    
      @process.state_name.should == :unmonitored
      @process.states_history.end?(:down, :unmonitored).should == true

      # should clear pid
      @process.pid.should == nil
    end

    it "stop if cant kill process, too moving to unmonitored" do
      start_ok_process(C.p1.merge(:stop_command => "which ruby"))

      @process.stop

      Eye::System.pid_alive?(@pid).should == true
      @process.state_name.should == :unmonitored
      @process.states_history.end?(:up, :unmonitored).should == true

      # should clear pid
      @process.pid.should == nil
    end
  end

end