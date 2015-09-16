require File.dirname(__FILE__) + '/../spec_helper'

describe "Process Restart, emulate some real hard cases" do
  [C.p1, C.p2].each do |cfg|
    it "emulate restart as stop,start where stop command does not kill" do
      # should send command, than wait grace time,
      # and than even if old process doesnot die, start another one, (looks like bug, but this is not, it just bad using, commands)

      # same situation, when stop command kills so long time, that process cant stop
      start_ok_process(cfg.merge(:stop_command => "kill -USR1 {PID}"))
      old_pid = @pid

      dont_allow(@process).check_crash
      @process.restart

      sleep 3
      @process.pid.should_not == old_pid

      Eye::System.pid_alive?(@pid).should == true

      @process.state_name.should == :up
      @process.watchers.keys.should == [:check_alive, :check_identity]

      @process.load_pid_from_file.should == @process.pid
      @process.states_history.states.should end_with(:up, :restarting, :stopping, :unmonitored, :starting, :up)

      File.read(@log).should include("USR1")
    end

    it "Bad restart command, invalid" do
      start_ok_process(cfg.merge(:restart_command => "asdfasdf sdf asd fasdf asdf"))

      dont_allow(@process).check_crash

      @process.restart
      Eye::System.pid_alive?(@pid).should == true
      @process.states_history.states.should seq(:up, :restarting, :up)
    end

    it "restart command timeouted" do
      start_ok_process(cfg.merge(:restart_command => "sleep 5", :restart_timeout => 3))
      @process.restart

      sleep 1
      @process.pid.should == @pid

      Eye::System.pid_alive?(@pid).should == true

      @process.state_name.should == :up
      @process.watchers.keys.should == [:check_alive, :check_identity]

      @process.load_pid_from_file.should == @process.pid
      @process.states_history.states.should end_with(:up, :restarting, :up)
    end
  end

  it "restart eye-daemonized lock-process from unmonitored status, and process really running (WAS a problem)" do
    start_ok_process(C.p4)
    @pid = @process.pid
    @process.unmonitor
    Eye::System.pid_alive?(@pid).should == true

    @process.restart
    @process.state_name.should == :up

    Eye::System.pid_alive?(@pid).should == false
    @process.load_pid_from_file.should_not == @pid
  end
end
