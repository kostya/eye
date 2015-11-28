require File.dirname(__FILE__) + '/../spec_helper'

describe "check pid identity" do
  it "check_identity method" do
    @process = process(C.p1)
    @process.start

    @pid = Eye::System.daemonize(C.p1[:start_command], C.p1)[:pid]
    File.open(C.p1[:pid_file], 'w'){|f| f.write(@pid) }
    change_ctime(C.p1[:pid_file], Time.parse('2010-01-01'))

    @process.state_name.should == :up
    @process.send :check_identity
    @process.state_name.should == :down
    @process.pid.should == nil
  end

  describe "monitor new process" do
    it "no identity, no process" do
      @process = process(C.p1)
      @process.get_identity.should be_nil

      @process.start
      @process.state_name.should == :up

      @process.get_identity.should be_within(1).of(Time.now)
      @process.compare_identity.should == :ok
    end

    it "identity, process, identity is ok" do
      @process = process(C.p1)

      @pid = Eye::System.daemonize(C.p1[:start_command], C.p1)[:pid]
      File.open(C.p1[:pid_file], 'w'){|f| f.write(@pid) }

      @process.start
      @process.state_name.should == :up
      @process.pid.should == @pid

      @process.get_identity.should be_within(5).of(Time.now)
      @process.compare_identity.should == :ok
    end

    it "identity, process, identity is bad, pid_file is very old" do
      @process = process(C.p1)

      @pid = Eye::System.daemonize(C.p1[:start_command], C.p1)[:pid]
      File.open(C.p1[:pid_file], 'w'){|f| f.write(@pid) }
      change_ctime(C.p1[:pid_file], Time.parse('2010-01-01'))
      @process.get_identity.year.should == 2010
      @process.compare_identity.should == :no_pid

      @process.start
      @process.state_name.should == :up
      @process.pid.should_not == @pid # !!!!

      Eye::System.pid_alive?(@pid).should == true
      Eye::System.pid_alive?(@process.pid).should == true

      @process.get_identity.should be_within(2).of(Time.now)
      @process.compare_identity.should == :ok

      @process.load_pid_from_file.should == @process.pid
    end

    it "check_identity disabled, identity, process, identity is bad, pid_file is very old" do
      @process = process(C.p1.merge(:check_identity => false))

      @pid = Eye::System.daemonize(C.p1[:start_command], C.p1)[:pid]
      File.open(C.p1[:pid_file], 'w'){|f| f.write(@pid) }
      change_ctime(C.p1[:pid_file], Time.parse('2010-01-01'))
      @process.get_identity.year.should == 2010
      @process.compare_identity.should == :ok

      @process.start
      @process.state_name.should == :up
      @process.pid.should == @pid

      Eye::System.pid_alive?(@pid).should == true

      @process.compare_identity.should == :ok

      @process.load_pid_from_file.should == @process.pid
    end
  end

  it "process changed identity while running" do
    @process = start_ok_process(C.p1.merge(:check_identity_period => 2))
    old_pid = @process.pid
    @pids << old_pid

    change_ctime(C.p1[:pid_file], 5.days.ago)
    sleep 5

    # here process should mark as crash, and restart again
    @process.states_history.states.should == [:unmonitored, :starting, :up, :down, :starting, :up]
    @process.scheduler_history.states.should == [:check_crash, :restore]

    @process.state_name.should == :up
    @process.pid.should_not == old_pid

    Eye::System.pid_alive?(old_pid).should == true
    Eye::System.pid_alive?(@process.pid).should == true

    @process.load_pid_from_file.should == @process.pid
  end

  it "just touch should not crash process" do
    @process = start_ok_process(C.p1.merge(:check_identity_period => 2, :check_identity_grace => 3))
    old_pid = @process.pid
    @pids << old_pid

    sleep 5

    change_ctime(C.p1[:pid_file], Time.now, true)
    sleep 5

    # here process should mark as crash, and restart again
    @process.states_history.states.should == [:unmonitored, :starting, :up]

    @process.state_name.should == :up
    @process.pid.should == old_pid
    @process.load_pid_from_file.should == @process.pid
  end

  it "check_identity disabled, process changed identity while running" do
    @process = start_ok_process(C.p1.merge(:check_identity_period => 2, :check_identity => false))
    old_pid = @process.pid
    @pids << old_pid

    change_ctime(C.p1[:pid_file], 5.days.ago)
    sleep 5

    # here process should mark as crash, and restart again
    @process.states_history.states.should == [:unmonitored, :starting, :up]

    @process.state_name.should == :up
    @process.pid.should == old_pid

    Eye::System.pid_alive?(old_pid).should == true
    @process.load_pid_from_file.should == @process.pid
  end

  describe "pid_file externally changed" do
    it "pid file was rewritten, but process with ok identity" do
      @process = start_ok_process(C.p2.merge(:check_identity_period => 2, :auto_update_pidfile_grace => 3, :check_identity_grace => 3))
      old_pid = @process.pid
      @pids << old_pid

      sleep 5

      @pid = Eye::System.daemonize(C.p1[:start_command], C.p1)[:pid]
      File.open(C.p2[:pid_file], 'w'){|f| f.write(@pid) }

      sleep 5

      # here process should mark as crash, and restart again
      @process.states_history.states.should == [:unmonitored, :starting, :up]

      @process.state_name.should == :up
      @process.pid.should == @pid

      Eye::System.pid_alive?(old_pid).should == true
      Eye::System.pid_alive?(@pid).should == true

      @process.load_pid_from_file.should == @process.pid
    end

    it "pid file was rewritten, but process with bad identity" do
      @process = start_ok_process(C.p2.merge(:check_identity_period => 20, :auto_update_pidfile_grace => 3, :revert_fuckup_pidfile_grace => 5,
        :check_identity_grace => 3))
      old_pid = @process.pid
      @pids << old_pid

      sleep 5

      @pid = Eye::System.daemonize(C.p1[:start_command], C.p1)[:pid]
      File.open(C.p2[:pid_file], 'w'){|f| f.write(@pid) }
      change_ctime(C.p2[:pid_file], 5.days.ago)

      sleep 7

      # here process should mark as crash, and restart again
      @process.states_history.states.should == [:unmonitored, :starting, :up]

      @process.state_name.should == :up

      Eye::System.pid_alive?(@pid).should == true
      Eye::System.pid_alive?(@process.pid).should == true
      @pid.should_not == @process.pid

      @process.load_pid_from_file.should == @process.pid
    end
  end

  describe "process send to stop, check identity before" do
    it "stop, identity bad -> just mark as crashed and unmonitored, remove pid_file" do
      @process = start_ok_process
      old_pid = @process.pid
      @pids << old_pid
      sleep 2
      change_ctime(C.p1[:pid_file], 5.days.ago)
      sleep 2
      @process.stop
      Eye::System.pid_alive?(old_pid).should == true
      @process.load_pid_from_file.should == nil
    end

    it "restart, identity bad -> just mark as crashed and unmonitored, remove pid_file" do
      @process = start_ok_process
      old_pid = @process.pid
      @pids << old_pid
      sleep 2
      change_ctime(C.p1[:pid_file], 5.days.ago)
      sleep 2
      @process.restart
      sleep 2
      @process.pid.should_not == old_pid
      Eye::System.pid_alive?(old_pid).should == true
      Eye::System.pid_alive?(@process.pid).should == true
      @process.load_pid_from_file.should == @process.pid
    end

    it "restart_command, identity bad -> just mark as crashed and unmonitored, remove pid_file" do
      @process = start_ok_process(C.p1.merge(:restart_command => "kill -USR1 {PID}"))
      old_pid = @process.pid
      @pids << old_pid
      sleep 2
      dont_allow(@process).execute
      change_ctime(C.p1[:pid_file], 5.days.ago)
      sleep 2
      @process.restart
      sleep 3
      @process.pid.should_not == old_pid
      Eye::System.pid_alive?(old_pid).should == true
      Eye::System.pid_alive?(@process.pid).should == true
      @process.load_pid_from_file.should == @process.pid
    end
  end

end
