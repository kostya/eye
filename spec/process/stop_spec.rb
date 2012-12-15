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

    it "stop should not clear pid by default for not daemonize" do
      start_ok_process(C.p2)

      @process.stop_process

      Eye::System.pid_alive?(@pid).should == false    
      @process.state_name.should == :down

      @process.load_pid_from_file.should == @pid
    end

    it "for not daemonize, but option enabled by manual" do
      start_ok_process(C.p2.merge(:control_pid => true))

      @process.stop_process

      Eye::System.pid_alive?(@pid).should == false    
      @process.state_name.should == :down

      @process.load_pid_from_file.should == nil
    end
  end

  it "stop process by default command" do
    start_ok_process

    dont_allow(@process).check_crush!
    @process.stop_process

    Eye::System.pid_alive?(@pid).should == false    
    @process.pid.should == @pid
    @process.state_name.should == :down
    @process.states_history.end?(:up, :stopping, :down).should == true
    @process.watchers.keys.should == []
  end

  it "stop process by specific command" do
    start_ok_process(C.p1.merge(:stop_command => "kill -9 {{PID}}"))

    dont_allow(@process).check_crush!
    @process.stop_process

    Eye::System.pid_alive?(@pid).should == false
    @process.state_name.should == :down    
  end

  it "bad command" do
    start_ok_process(C.p1.merge(:stop_command => "kill -0 {{PID}}"))

    @process.stop_process

    Eye::System.pid_alive?(@pid).should == true
    @process.state_name.should == :unmonitored # cant stop with this command, so :unmonitored
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
  end

  it "stop process by stop_signals" do
    start_ok_process(C.p1.merge(:stop_signals => [9, 2.seconds]))

    @process.stop_process!
    sleep 1
    Eye::System.pid_alive?(@pid).should == false
  end

  it "stop process by stop_signals" do
    start_ok_process(C.p1.merge(:stop_signals => ['usr1', 3.seconds, :TERM, 2.seconds]))

    @process.stop_process!
    sleep 1.5
    Eye::System.pid_alive?(@pid).should == true
    sleep 1.5
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
  end

  it "stop process by stop_signals as commands" 

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