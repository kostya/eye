require File.dirname(__FILE__) + '/../spec_helper'

describe "Process Controller" do

  describe "monitor" do
    it "monitor should call start, as the auto_start is default" do
      @process = process C.p1

      proxy(@process).start
      @process.monitor
      sleep 1

      @process.state_name.should == :up
    end

    it "without auto_start and process not running" do
      @process = process C.p1.merge(:auto_start => false)
      @process.monitor
      sleep 1

      @process.state_name.should == :unmonitored
    end

    it "without auto_start and process already running" do
      @pid = Eye::System.daemonize(C.p1[:start_command], C.p1)[:pid]
      Eye::System.pid_alive?(@pid).should == true
      File.open(C.p1[:pid_file], 'w'){|f| f.write(@pid) }
      sleep 2

      @process = process C.p1.merge(:auto_start => false)
      @process.monitor
      sleep 1

      @process.state_name.should == :up
      @process.pid.should == @pid
    end

  end

  describe "unmonitor" do
    [C.p1, C.p2].each do |cfg|
      it "should just forget about any process #{cfg[:name]}" do
        start_ok_process(cfg)
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

  describe "delete" do
    it "delete monitoring, not kill process" do
      start_ok_process
      old_pid = @process.pid

      @process.delete
      Eye::System.pid_alive?(old_pid).should == true
      sleep 0.3
      @process.alive?.should == false

      @process = nil
    end

    it "if stop_on_delete process die" do
      start_ok_process(C.p1.merge(:stop_on_delete => true))
      old_pid = @process.pid

      @process.delete
      Eye::System.pid_alive?(old_pid).should == false
      sleep 0.3
      @process.alive?.should == false

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

    it "if cant kill process, moving to unmonitored too" do
      start_ok_process(C.p1.merge(:stop_command => "which ruby"))

      @process.watchers.keys.should == [:check_alive]

      @process.stop

      Eye::System.pid_alive?(@pid).should == true
      @process.state_name.should == :unmonitored
      @process.states_history.end?(:stopping, :unmonitored).should == true

      # should clear pid
      @process.pid.should == nil
      @process.watchers.keys.should == []
    end
  end

  describe "process cant start, crash each time" do
    before :each do
      @process = process(C.p2.merge(:start_command => C.p2[:start_command] + " -r" ))
      @process.send_command :start
    end

    it "we send command to stop it" do
      # process flapping here some times
      sleep 10

      # now send stop command
      @process.send_command :stop
      sleep 7

      # process should be stopped here
      @process.state_name.should == :unmonitored
    end

    it "we send command to unmonitor it" do
      # process flapping here some times
      sleep 10

      # now send stop command
      @process.send_command :unmonitor
      sleep 7

      # process should be stopped here
      @process.state_name.should == :unmonitored
    end
  end

  describe "signal" do
    before :each do
      @process = process(C.p1)
      @process.pid = 122345
    end

    it "mock send_signal" do
      mock(@process).send_signal(9)
      @process.signal(9)

      mock(@process).send_signal('9')
      @process.signal('9')
    end
  end

end