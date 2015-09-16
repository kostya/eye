require File.dirname(__FILE__) + '/../spec_helper'

describe "Process Start" do

  it "process already runned, started new process" do
    # something already started process
    @pid = Eye::System.daemonize(C.p1[:start_command], C.p1)[:pid]
    Eye::System.pid_alive?(@pid).should == true
    File.open(C.p1[:pid_file], 'w'){|f| f.write(@pid) }

    # should not try to start something
    dont_allow(Eye::System).daemonize
    dont_allow(Eye::System).execute

    # when start process
    @process = process C.p1
    @process.start.should == :ok

    # wait while monitoring completely started
    sleep 0.5

    # pid and should be ok
    @process.pid.should == @pid
    @process.load_pid_from_file.should == @pid

    @process.state_name.should == :up
    @process.watchers.keys.should == [:check_alive, :check_identity]
  end

  it "process started and up, receive command start" do
    @process = process C.p1
    @process.start.should == {:pid=>@process.pid, :exitstatus => 0}
    sleep 0.5
    @process.state_name.should == :up
    @process.watchers.keys.should == [:check_alive, :check_identity]

    @process.start.should == :ok
    sleep 1
    @process.state_name.should == :up
    @process.watchers.keys.should == [:check_alive, :check_identity]
  end

  [C.p1, C.p2].each do |cfg|
    it "start new process, with config #{cfg[:name]}" do
      @process = process cfg
      @process.start.should == {:pid=>@process.pid, :exitstatus => 0}

      sleep 0.5

      @pid = @process.pid
      @process.load_pid_from_file.should == @pid

      @process.state_name.should == :up
      @process.watchers.keys.should == [:check_alive, :check_identity]
    end

    it "pid_file already exists, but process not, with config #{cfg[:name]}" do
      File.open(C.p1[:pid_file], 'w'){|f| f.write(1234567) }

      @process = process cfg
      @process.start.should == {:pid=>@process.pid, :exitstatus => 0}

      sleep 0.5

      @pid = @process.pid
      @pid.should_not == 1234567
      @process.load_pid_from_file.should == @pid

      @process.state_name.should == :up
    end

    it "process crashed, with config #{cfg[:name]}" do
      @process = process(cfg.merge(:start_command => cfg[:start_command] + " -r" ))
      @process.start.should == {:error=>:not_really_running}

      sleep 1

      if cfg[:daemonize]
        @process.load_pid_from_file.should == nil
      else
        @process.load_pid_from_file.should > 0
      end

      # should try to up process many times
      @process.states_history.states.should seq(:unmonitored, :starting, :down, :starting)
      @process.states_history.states.should contain_only(:unmonitored, :starting, :down)

      @process.watchers.keys.should == []
    end

    it "start with invalid command" do
      @process = process(cfg.merge(:start_command => "asdf asdf1 r f324 f324f 32f44f"))
      mock(@process).check_crash
      res = @process.start
      res[:error].should start_with("#<Errno::ENOENT: No such file or directory")

      sleep 0.5

      @process.pid.should == nil
      @process.load_pid_from_file.should == nil
      [:starting, :down].should include(@process.state_name)
      @process.states_history.states.should contain_only(:unmonitored, :starting, :down)
    end

    it "start PROBLEM with stdout permissions" do
      @process = process(cfg.merge(:stdout => "/var/run/1.log"))
      mock(@process).check_crash
      res = @process.start
      res[:error].should start_with("#<Errno::EACCES: Permission denied")

      sleep 0.5

      @process.pid.should == nil
      @process.load_pid_from_file.should == nil
      [:starting, :down].should include(@process.state_name)
      @process.states_history.states.should contain_only(:unmonitored, :starting, :down)
    end

    it "start PROBLEM binary permissions" do
      @process = process(cfg.merge(:start_command => "./sample.rb"))
      mock(@process).check_crash
      res = @process.start
      res[:error].should start_with("#<Errno::EACCES: Permission denied")

      sleep 0.5

      @process.pid.should == nil
      @process.load_pid_from_file.should == nil
      [:starting, :down].should include(@process.state_name)
      @process.states_history.states.should contain_only(:unmonitored, :starting, :down)
    end

  end

  it "C.p1 pid_file failed to write" do
    @process = process(C.p1.merge(:pid_file => "/tmpasdfasdf/asdfa/dfa/df/ad/fad/fd.pid"))
    res = @process.start
    res.should == {:error=>:cant_write_pid}

    sleep 1

    [:starting, :down].should include(@process.state_name)
    @process.states_history.states.should seq(:unmonitored, :starting, :down, :starting)
    @process.states_history.states.should contain_only(:unmonitored, :starting, :down)

    @process.watchers.keys.should == []
  end

  it "C.p2 pid_file failed to write" do
    pid = "/tmpasdfasdf/asdfa/dfa/df/ad/fad/fd.pid"
    @process = process(C.p2.merge(:pid_file => pid,
      :start_command => "ruby sample.rb -d --pid #{pid} --log #{C.log_name}"))
    res = @process.start
    res.should == {:error=>:pid_not_found}

    sleep 1

    [:starting, :down].should include(@process.state_name)
    @process.states_history.states.should seq(:unmonitored, :starting, :down, :starting)
    @process.states_history.states.should contain_only(:unmonitored, :starting, :down)

    @process.watchers.keys.should == []
  end

  it "long process with #{C.p1[:name]} (with daemonize)" do
    # this is no matter for starting
    @process = process(C.p1.merge(:start_command => C.p1[:start_command] + " --daemonize_delay 3",
      :start_grace => 2.seconds ))
    @process.start.should == {:pid=>@process.pid, :exitstatus => 0}

    sleep 5
    Eye::System.pid_alive?(@process.pid).should == true
    @process.state_name.should == :up
  end

  it "long process with #{C.p2[:name]}" do
    @process = process(C.p2.merge(:start_command => C.p2[:start_command] + " --daemonize_delay 3",
      :start_timeout => 2.seconds))
    @process.start.should == {:error=>"#<Timeout::Error: execution expired>"}

    sleep 0.5
    @process.pid.should == nil
    @process.load_pid_from_file.should == nil

    [:starting, :down].should include(@process.state_name)

    @process.states_history.states.should seq(:unmonitored, :starting, :down, :starting)
    @process.states_history.states.should contain_only(:unmonitored, :starting, :down)
  end

  it "long process with #{C.p2[:name]} but start_timeout is OK" do
    @process = process(C.p2.merge(:start_command => C.p2[:start_command] + " --daemonize_delay 3",
      :start_timeout => 10.seconds))
    @process.start.should == {:pid => @process.pid, :exitstatus => 0}

    @process.load_pid_from_file.should == @process.pid
    @process.state_name.should == :up
  end

  # O_o, what checks this spec
  it "blocking start with lock" do
    @process = process(C.p2.merge(:start_command => C.p2[:start_command] + " --daemonize_delay 3 -L #{C.p2_lock}", :start_timeout => 2.seconds))
    @process.start.should == {:error => "#<Timeout::Error: execution expired>"}

    sleep 0.5
    @process.pid.should == nil
    @process.load_pid_from_file.should == nil

    [:starting, :down].should include(@process.state_name)

    @process.states_history.states.should seq(:unmonitored, :starting, :down, :starting)
    @process.states_history.states.should contain_only(:unmonitored, :starting, :down)
  end

  it "bad config daemonize self daemonized process pid the same" do
    # little crazy behaviour, but process after first death, upped from pid_file pid
    # NOT RECOMENDED FOR USE CASE
    @process = process(C.p2.merge(:daemonize => true, :start_grace => 10.seconds))
    old_pid = @process.pid

    @process.start.should == {:error => :not_really_running}

    sleep 5

    # should reload process from pid_file
    @process.state_name.should == :up
    @process.pid.should_not == old_pid
    @process.load_pid_from_file.should == @process.pid
  end

  it "bad config daemonize self daemonized process pid different" do
    # NOT RECOMENDED FOR USE CASE
    @process = process(C.p2.merge(:daemonize => true, :pid_file => C.p2_pid, :start_grace => 10.seconds,
      :environment => {"FAILSAFE_PID_FILE" => C.just_pid}))
    @process.start.should == {:error => :not_really_running}
    @process.pid.should == nil

    # to ensure kill this process
    sleep 1
    if File.exist?(C.just_pid)
      @process.pid = File.read(C.just_pid).to_i
    end
  end

  it "without start command" do
    @process = process(C.p2.merge(:start_command => nil))
    @process.start.should == :no_start_command
    sleep 1
    @process.unmonitored?.should == true
  end

  [:up, :starting, :stopping, :restarting].each do |st|
    it "should not start from #{st}" do
      @process = process(C.p1)
      @process.state = st.to_s # force set state

      dont_allow(Eye::System).daemonize
      dont_allow(Eye::System).execute

      @process.start.should == :state_error
      @process.state_name.should == st

      @process.pid.should == nil
    end
  end

end
