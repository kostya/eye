require File.dirname(__FILE__) + '/../spec_helper'

describe "Process Monitoring" do

  [C.p1, C.p2].each do |cfg|

    it "process crashed, should restart #{cfg[:name]}" do
      start_ok_process(cfg)
      old_pid = @pid

      die_process!(@pid)
      mock(@process).notify(:info, anything)

      sleep 7 # wait until monitor upping process

      @pid = @process.pid
      @pid.should_not == old_pid

      Eye::System.pid_alive?(old_pid).should == false
      Eye::System.pid_alive?(@pid).should == true

      @process.state_name.should == :up
      @process.states_history.states.should seq(:down, :starting, :up)
      @process.watchers.keys.should == [:check_alive, :check_identity]
      @process.load_pid_from_file.should == @process.pid
    end

    it "process crashed, should restart #{cfg[:name]} in restore_in interval" do
      start_ok_process(cfg.merge(:restore_in => 3.seconds))
      old_pid = @pid

      die_process!(@pid)
      mock(@process).notify(:info, anything)

      sleep 10 # wait until monitor upping process

      @pid = @process.pid
      @pid.should_not == old_pid

      Eye::System.pid_alive?(old_pid).should == false
      Eye::System.pid_alive?(@pid).should == true

      @process.state_name.should == :up
      @process.states_history.states.should seq(:down, :starting, :up)
      @process.watchers.keys.should == [:check_alive, :check_identity]
      @process.load_pid_from_file.should == @process.pid
    end
  end

  it "if keep_alive disabled, process should not up" do
    start_ok_process(C.p1.merge(:keep_alive => false))
    old_pid = @process.pid

    die_process!(@pid)

    sleep 7 # wait until monitor upping process

    @process.pid.should == nil
    Eye::System.pid_alive?(@pid).should == false

    @process.state_name.should == :unmonitored
    @process.watchers.keys.should == []
    @process.states_history.states.should end_with(:up, :down, :unmonitored)
    @process.load_pid_from_file.should == nil
  end

  it "process in status unmonitored should not up automatically" do
    start_ok_process(C.p1)
    old_pid = @pid

    @process.unmonitor
    @process.state_name.should == :unmonitored

    die_process!(@pid)

    sleep 7 # wait until monitor upping process

    @process.pid.should == nil

    Eye::System.pid_alive?(old_pid).should == false

    @process.state_name.should == :unmonitored
    @process.watchers.keys.should == []
    @process.load_pid_from_file.should == old_pid
  end

  it "EMULATE UNICORN hard understanding restart case" do
    start_ok_process(C.p2)
    old_pid = @pid

    # rewrite by another :)
    @pid = Eye::System.daemonize("ruby sample.rb", {:environment => {"ENV1" => "SECRET1"},
      :working_dir => C.p2[:working_dir], :stdout => @log})[:pid]

    File.open(C.p2[:pid_file], 'w'){|f| f.write(@pid) }

    sleep 5

    # both processes exists now
    # and in pid_file writed second pid
    @process.load_pid_from_file.should == @pid
    @process.pid.should == old_pid

    die_process!(old_pid)

    sleep 5 # wait until monitor upping process

    @process.pid.should == @pid
    old_pid.should_not == @pid
    @process.load_pid_from_file.should == @pid

    Eye::System.pid_alive?(old_pid).should == false
    Eye::System.pid_alive?(@pid).should == true

    @process.state_name.should == :up
    @process.watchers.keys.should == [:check_alive, :check_identity]
    @process.load_pid_from_file.should == @process.pid
  end

end
