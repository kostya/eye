require File.dirname(__FILE__) + '/../spec_helper'

describe "dependency" do
  after :each do
    @pids << @process_a.pid if @process_a && @process_a.alive?
    @pids << @process_b.pid if @process_b && @process_b.alive?
    @pids << @process_c.pid if @process_c && @process_c.alive?
  end

  describe "start" do
    before :each do
      @c = Eye::Controller.new
      silence_warnings { Eye::Control = @c }

      conf = <<-D
        # dependency :b -> :a
        #   :b want :a to be upped

        Eye.app :d do
          auto_start false
          working_dir "#{C.sample_dir}"

          process(:a) do
            start_command "sleep 100"
            daemonize true
            pid_file "#{C.p1_pid}"
            start_grace 3.seconds
          end

          process(:b) do
            start_command "sleep 100"
            daemonize true
            pid_file "#{C.p2_pid}"
            start_grace 0.5

            depend_on :a, :wait_timeout => 5.seconds
          end

        end
      D
      @c.load_content(conf)
      sleep 0.5
      @process_a = @c.process_by_name("a")
      @process_a.state_name.should == :unmonitored
      @pid_a = @process_a.pid
      @process_b = @c.process_by_name("b")
      @process_b.state_name.should == :unmonitored
    end

    it "start :a" do
      @process_a.send_command :start
      sleep 4

      @process_a.state_name.should == :up
      @process_b.state_name.should == :unmonitored

      @process_a.states_history.states.should == [:unmonitored, :starting, :up]
      @process_b.states_history.states.should == [:unmonitored]

      @process_a.schedule_history.states.should == [:monitor, :unmonitor, :start]
      @process_b.schedule_history.states.should == [:monitor, :unmonitor]
    end

    it "start :b" do
      @process_b.send_command :start
      sleep 4

      @process_a.state_name.should == :up
      @process_b.state_name.should == :up

      @process_a.states_history.states.should == [:unmonitored, :starting, :up]
      @process_b.states_history.states.should == [:unmonitored, :starting, :up]

      @process_a.schedule_history.states.should == [:monitor, :unmonitor, :start]
      @process_b.schedule_history.states.should == [:monitor, :unmonitor, :start]
    end

    it "start :b, and :a not started (crashed)" do
      @process_a.config[:start_command] = "asdfasdf asf "
      @process_b.send_command :start

      dont_allow(@process_b).daemonize_process
      sleep 7

      @process_a.state_name.should == :unmonitored
      @process_b.state_name.should == :unmonitored

      @process_b.states_history.states.should == [:unmonitored, :starting, :unmonitored]
    end

    it "start :b, and :a not started (crashed), than a somehow up, should reschedule and up" do
      @process_a.config[:start_command] = "asdfasdf asf "
      @process_a.config[:start_grace] = 1.seconds
      @process_b.config[:triggers].detect{|k, v| k.to_s =~ /wait_dep/}[1][:retry_after] = 2.seconds
      @process_b.send_command :start
      sleep 6
      @process_a.state_name.should == :unmonitored
      @process_b.state_name.should == :unmonitored

      @process_a.config[:start_command] = "sleep 100"
      sleep 3

      @process_a.state_name.should == :up
      @process_b.state_name.should == :up

      @process_b.states_history.states.should == [:unmonitored, :starting, :unmonitored, :starting, :up]
    end

    it "start :b, and :a started after big timeout (> wait_timeout)" do
      @process_a.config[:start_grace] = 6.seconds
      @process_b.config[:triggers].detect{|k, v| k.to_s =~ /wait_dep/}[1][:retry_after] = 2.seconds
      @process_b.send_command :start
      sleep 10

      @process_a.state_name.should == :up
      @process_b.state_name.should == :up

      @process_a.states_history.states.should == [:unmonitored, :starting, :up]
      @process_b.states_history.states.should == [:unmonitored, :starting, :unmonitored, :starting, :up]

      @process_a.schedule_history.states.should == [:monitor, :unmonitor, :start]
      @process_b.schedule_history.states.should == [:monitor, :unmonitor, :start, :start]
    end

    it "start :b and should_start = false" do
      @process_b.config[:triggers].detect{|k, v| k.to_s =~ /wait_dep/}[1][:should_start] = false
      @process_b.config[:triggers].detect{|k, v| k.to_s =~ /wait_dep/}[1][:retry_after] = 2.seconds

      @process_b.send_command :start
      sleep 4

      @process_a.state_name.should == :unmonitored
      @process_b.state_name.should == :starting

      # then somehow a :up
      @process_a.start
      sleep 3

      # now b should start automatically
      @process_a.state_name.should == :up
      @process_b.state_name.should == :up

      @process_a.states_history.states.should == [:unmonitored, :starting, :up]
      @process_b.states_history.states.should == [:unmonitored, :starting, :unmonitored, :starting, :up]

      @process_a.schedule_history.states.should == [:monitor, :unmonitor]
      @process_b.schedule_history.states.should == [:monitor, :unmonitor, :start, :start]
    end
  end

  describe "some actions" do
    before :each do
      @c = Eye::Controller.new
      silence_warnings { Eye::Control = @c }

      conf = <<-D
        # dependency :b -> :a
        #   :b want :a to be upped

        Eye.app :d do
          working_dir "#{C.sample_dir}"
          start_grace 0.5
          check_alive_period 0.5

          process(:a) do
            start_command "sleep 100"
            daemonize true
            pid_file "#{C.p1_pid}"
          end

          process(:b) do
            start_command "sleep 100"
            daemonize true
            pid_file "#{C.p2_pid}"

            depend_on :a
          end

        end
      D
      @c.load_content(conf)
      @process_a = @c.process_by_name("a")
      @process_b = @c.process_by_name("b")
      [@process_a, @process_b].each do |p|
        p.wait_for_condition(2, 0.3) { p.state_name == :up }
      end
      @pid_a = @process_a.pid
      @pid_b = @process_b.pid
      @pids << @process_a.pid
      @pids << @process_b.pid

      Eye::System.pid_alive?(@pid_a).should == true
      Eye::System.pid_alive?(@pid_b).should == true
    end

    it "crashed :a, should restore :a and restart :b" do
      Eye::System.send_signal(@process_a.pid, 9)
      sleep 6
      @process_a.state_name.should == :up
      @process_b.state_name.should == :up

      @process_a.pid.should_not == @pid_a
      @process_b.pid.should_not == @pid_b

      @process_a.states_history.states.should == [:unmonitored, :starting, :up, :down, :starting, :up]
      @process_b.states_history.states.should == [:unmonitored, :starting, :up, :restarting, :stopping, :down, :starting, :up]

      @process_a.schedule_history.states[0,4].should == [:monitor, :start, :check_crash, :restore]
      @process_b.schedule_history.states.should == [:monitor, :restart]
    end

    it "crashed :b, should only restore :b" do
      Eye::System.send_signal(@process_b.pid, 9)
      sleep 2

      @process_a.state_name.should == :up
      @process_b.state_name.should == :up

      Eye::System.pid_alive?(@pid_a).should == true
      Eye::System.pid_alive?(@pid_b).should == false
      Eye::System.pid_alive?(@process_b.pid).should == true

      @pid_a.should == @process_a.pid
      @pid_b.should_not == @process_b.pid

      @process_a.states_history.states.should == [:unmonitored, :starting, :up]
      @process_b.states_history.states.should == [:unmonitored, :starting, :up, :down, :starting, :up]

      @process_a.schedule_history.states.should == [:monitor, :start]
      @process_b.schedule_history.states.should == [:monitor, :check_crash, :restore]
    end

    it "stop :a, should stop :b" do
      @process_a.stop
      sleep 1

      @process_a.state_name.should == :unmonitored
      @process_b.state_name.should == :unmonitored

      Eye::System.pid_alive?(@pid_a).should == false
      Eye::System.pid_alive?(@pid_b).should == false

      @process_a.states_history.states.should == [:unmonitored, :starting, :up, :stopping, :down, :unmonitored]
      @process_b.states_history.states.should == [:unmonitored, :starting, :up, :stopping, :down, :unmonitored]

      @process_a.schedule_history.states.should == [:monitor, :start]
      @process_b.schedule_history.states.should == [:monitor, :stop]
    end

    it "stop :b" do
      @process_b.stop
      sleep 1

      @process_a.state_name.should == :up
      @process_b.state_name.should == :unmonitored

      Eye::System.pid_alive?(@pid_a).should == true
      Eye::System.pid_alive?(@pid_b).should == false

      @process_a.states_history.states.should == [:unmonitored, :starting, :up]
      @process_b.states_history.states.should == [:unmonitored, :starting, :up, :stopping, :down, :unmonitored]

      @process_a.schedule_history.states.should == [:monitor, :start]
      @process_b.schedule_history.states.should == [:monitor]
    end

    it "unmonitor :a, should unmonitor :b" do
      @process_a.unmonitor
      sleep 1

      @process_a.state_name.should == :unmonitored
      @process_b.state_name.should == :unmonitored

      Eye::System.pid_alive?(@pid_a).should == true
      Eye::System.pid_alive?(@pid_b).should == true

      @process_a.states_history.states.should == [:unmonitored, :starting, :up, :unmonitored]
      @process_b.states_history.states.should == [:unmonitored, :starting, :up, :unmonitored]

      @process_a.schedule_history.states.should == [:monitor, :start]
      @process_b.schedule_history.states.should == [:monitor, :unmonitor]
    end

    it "unmonitor :b" do
      @process_b.unmonitor
      sleep 1

      @process_a.state_name.should == :up
      @process_b.state_name.should == :unmonitored

      Eye::System.pid_alive?(@pid_a).should == true
      Eye::System.pid_alive?(@pid_b).should == true

      @process_a.states_history.states.should == [:unmonitored, :starting, :up]
      @process_b.states_history.states.should == [:unmonitored, :starting, :up, :unmonitored]

      @process_a.schedule_history.states.should == [:monitor, :start]
      @process_b.schedule_history.states.should == [:monitor]
    end

    it "restart :a, should restart :b" do
      @process_a.restart
      sleep 2

      @process_a.state_name.should == :up
      @process_b.state_name.should == :up

      Eye::System.pid_alive?(@pid_a).should == false
      Eye::System.pid_alive?(@pid_b).should == false

      @process_a.states_history.states.should == [:unmonitored, :starting, :up, :restarting, :stopping, :down, :starting, :down, :starting, :up]
      @process_b.states_history.states.should == [:unmonitored, :starting, :up, :restarting, :stopping, :down, :starting, :up]

      @process_a.schedule_history.states.should == [:monitor, :start, :start, :check_crash, :restore]
      @process_b.schedule_history.states.should == [:monitor, :restart]
    end

    it "restart :b" do
      @process_b.restart
      sleep 1

      @process_a.state_name.should == :up
      @process_b.state_name.should == :up

      Eye::System.pid_alive?(@pid_a).should == true
      Eye::System.pid_alive?(@pid_b).should == false

      @process_a.states_history.states.should == [:unmonitored, :starting, :up]
      @process_b.states_history.states.should == [:unmonitored, :starting, :up, :restarting, :stopping, :down, :starting, :up]

      @process_a.schedule_history.states.should == [:monitor, :start]
      @process_b.schedule_history.states.should == [:monitor]
    end

    it "restart send to both" do
      pending
      @process_a.send_command :restart
      @process_b.send_command :restart
      sleep 3.5

      @process_a.state_name.should == :up
      @process_b.state_name.should == :up

      Eye::System.pid_alive?(@pid_a).should == false
      Eye::System.pid_alive?(@pid_b).should == false

      @process_a.states_history.states.should == [:unmonitored, :starting, :up, :restarting, :stopping, :down, :starting, :up]
      @process_b.states_history.states.should == [:unmonitored, :starting, :up, :restarting, :stopping, :down, :starting, :up]

      @process_a.schedule_history.states.should == [:monitor, :start]
      @process_b.schedule_history.states.should == [:monitor]
    end

    it ":a was deleted, should successfully restart :b" do
      @c.send_command :delete, 'a'

      @process_b.restart
      sleep 1

      @process_b.state_name.should == :up
      Eye::System.pid_alive?(@pid_b).should == false
      @process_b.states_history.states.should == [:unmonitored, :starting, :up, :restarting, :stopping, :down, :starting, :up]
      @process_b.schedule_history.states.should == [:monitor]
    end

    it ":b was deleted, should successfully restart :a" do
      @c.send_command :delete, 'b'

      @process_a.restart
      sleep 1

      @process_a.state_name.should == :up
      Eye::System.pid_alive?(@pid_a).should == false
      @process_a.states_history.states.should == [:unmonitored, :starting, :up, :restarting, :stopping, :down, :starting, :up]
      @process_a.schedule_history.states.should == [:monitor, :start]
    end
  end
end
