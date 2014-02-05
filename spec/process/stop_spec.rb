require File.dirname(__FILE__) + '/../spec_helper'

describe "Process Stop" do

  describe "clear_pid_file" do
    it "stop should clear pid by default for daemonize" do
      start_ok_process(C.p1)

      @process.stop_process

      Eye::System.pid_alive?(@pid).should == false
      @process.state_name.should == :down

      @process.load_pid_from_file.should == nil
    end

    it "stop should clear pid by default for not daemonize" do
      start_ok_process(C.p2)

      @process.stop_process

      Eye::System.pid_alive?(@pid).should == false
      @process.state_name.should == :down

      @process.load_pid_from_file.should == nil
    end

    it "for not daemonize, but option enabled by manual" do
      start_ok_process(C.p2.merge(:clear_pid => false))

      @process.stop_process

      Eye::System.pid_alive?(@pid).should == false
      @process.state_name.should == :down

      @process.load_pid_from_file.should == @pid
    end
  end

  it "stop process by default command" do
    start_ok_process

    dont_allow(@process).check_crash
    @process.stop_process

    Eye::System.pid_alive?(@pid).should == false
    @process.pid.should == @pid
    @process.state_name.should == :down
    @process.states_history.end?(:up, :stopping, :down).should == true
    @process.watchers.keys.should == []
    @process.load_pid_from_file.should == nil
  end

  it "stop process by default command, and its not die by TERM, should stop anyway" do
    start_ok_process(C.p2.merge(:start_command => C.p2[:start_command] + " -T"))
    Eye::System.pid_alive?(@pid).should == true

    dont_allow(@process).check_crash
    @process.stop_process

    Eye::System.pid_alive?(@pid).should == false
    @process.pid.should == @pid
    @process.state_name.should == :down
    @process.states_history.end?(:up, :stopping, :down).should == true
    @process.watchers.keys.should == []
    @process.load_pid_from_file.should == nil
  end

  it "stop process by specific command" do
    start_ok_process(C.p1.merge(:stop_command => "kill -9 {PID}"))

    dont_allow(@process).check_crash
    @process.stop_process

    Eye::System.pid_alive?(@pid).should == false
    @process.state_name.should == :down
    @process.load_pid_from_file.should == nil
  end

  it "bad command" do
    start_ok_process(C.p1.merge(:stop_command => "kill -0 {PID}"))

    @process.stop_process

    Eye::System.pid_alive?(@pid).should == true
    @process.state_name.should == :unmonitored # cant stop with this command, so :unmonitored

    @process.load_pid_from_file.should == @pid # needs
  end

  it "bad command timeouted" do
    start_ok_process(C.p1.merge(:stop_command => "sleep 2", :stop_timeout => 1))

    @process.stop_process

    Eye::System.pid_alive?(@pid).should == true
    @process.state_name.should == :unmonitored # cant stop with this command, so :unmonitored

    @process.load_pid_from_file.should == @pid # needs
  end

  it "watch_file" do
    wf = File.join(C.p1[:working_dir], %w{1111.stop})
    start_ok_process(C.p1.merge(:stop_command => "touch #{wf}",
      :start_command => C.p1[:start_command] + " -w #{wf}"))

    @process.stop_process

    Eye::System.pid_alive?(@pid).should == false
    @process.state_name.should == :down

    File.exists?(wf).should == false

    data = File.read(@log)
    data.should include("watch file finded")

    @process.load_pid_from_file.should == nil
  end

  it "stop process by stop_signals" do
    start_ok_process(C.p1.merge(:stop_signals => [9, 2.seconds]))

    @process.async.stop_process
    sleep 1
    Eye::System.pid_alive?(@pid).should == false

    @process.load_pid_from_file.should == nil
  end

  it "stop process by stop_signals" do
    start_ok_process(C.p1.merge(:stop_signals => ['usr1', 3.seconds, :TERM, 2.seconds]))

    @process.async.stop_process
    sleep 1.5

    # not blocking actor
    should_spend(0) do
      @process.name.should == 'blocking process'
    end

    Eye::System.pid_alive?(@pid).should == true
    sleep 1.3
    Eye::System.pid_alive?(@pid).should == true
    sleep 1
    Eye::System.pid_alive?(@pid).should == false

    # should capture log
    data = File.read(@log)
    data.should include("USR1 signal")
  end

  it "long stop" do
    start_ok_process(C.p3)
    pid = @process.pid

    @process.stop_process
    @process.state_name.should == :down

    Eye::System.pid_alive?(pid).should == false

    @process.load_pid_from_file.should == nil
  end

  # it "stop process by stop_signals and commands"

  [:unmonitored, :down, :starting, :stopping].each do |st|
    it "no stop from #{st}" do
      @process = process(C.p1)
      @process.state = st.to_s # force set state

      dont_allow(@process).kill_process

      @process.stop_process
      @process.state_name.should == st
    end
  end

end