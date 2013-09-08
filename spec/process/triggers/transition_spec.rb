require File.dirname(__FILE__) + '/../../spec_helper'

describe "Trigger Transition" do
  before :each do
    @c = Eye::Controller.new
  end

  describe "delete file on state" do
    before :each do
      cfg = <<-D
        Eye.application("bla") do
          working_dir "#{C.sample_dir}"
          process("1") do
            pid_file "#{C.p1_pid}"
            start_command "sleep 30"
            daemonize true
            trigger :transition, :to => :down, :do => ->{ ::File.delete("#{C.tmp_file}") }
          end
        end
      D

      with_temp_file(cfg){ |f| @c.load(f) }
      sleep 5
      @process = @c.process_by_name("1")
    end

    it "should delete file when stop" do
      File.open(C.tmp_file, 'w'){ |f| f.write "aaa" }
      File.exists?(C.tmp_file).should == true
      @process.stop
      File.exists?(C.tmp_file).should == false
    end
  end

  describe "delete file on event" do
    before :each do
      cfg = <<-D
        Eye.application("bla") do
          working_dir "#{C.sample_dir}"
          process("1") do
            pid_file "#{C.p1_pid}"
            start_command "sleep 30"
            daemonize true
            trigger :transition, :event => :crashed, :do => ->{ ::File.delete("#{C.tmp_file}") }
          end
        end
      D

      with_temp_file(cfg){ |f| @c.load(f) }
      sleep 5
      @process = @c.process_by_name("1")
    end

    it "should delete file when stop" do
      File.open(C.tmp_file, 'w'){ |f| f.write "aaa" }
      File.exists?(C.tmp_file).should == true
      force_kill_pid(@process.pid)
      sleep 5
      File.exists?(C.tmp_file).should == false
    end
  end

  describe "call method" do
    before :each do
      cfg = <<-D
        def hashdhfhsdfh(process)
          ::File.delete("#{C.tmp_file}")
        end

        Eye.application("bla") do
          working_dir "#{C.sample_dir}"
          process("1") do
            pid_file "#{C.p1_pid}"
            start_command "sleep 30"
            daemonize true
            trigger :transition, :event => :crashed, :do => :hashdhfhsdfh
          end
        end
      D

      with_temp_file(cfg){ |f| @c.load(f) }
      sleep 5
      @process = @c.process_by_name("1")
    end

    it "should delete file when stop" do
      File.open(C.tmp_file, 'w'){ |f| f.write "aaa" }
      File.exists?(C.tmp_file).should == true
      force_kill_pid(@process.pid)
      sleep 5
      File.exists?(C.tmp_file).should == false
    end
  end

  describe "multiple triggers" do
    before :each do
      cfg = <<-D
        Eye.application("bla") do
          working_dir "#{C.sample_dir}"
          process("1") do
            pid_file "#{C.p1_pid}"
            start_command "sleep 30"
            daemonize true
            trigger :transition1, :to => :up, :do => ->{ info "touch #{C.tmp_file}"; ::File.open("#{C.tmp_file}", 'w') }
            trigger :transition2, :to => :down, :do => ->{ info "rm #{C.tmp_file}"; ::File.delete("#{C.tmp_file}") }
          end
        end
      D

      with_temp_file(cfg){ |f| @c.load(f) }
      sleep 5
      @process = @c.process_by_name("1")
    end

    it "should delete file when stop" do
      File.exists?(C.tmp_file).should == true
      @process.stop
      File.exists?(C.tmp_file).should == false
    end
  end

  describe "Kill process childs when process crashed or stop" do
    before :each do
      cfg = <<-D
        Eye.application("bla") do
          working_dir "#{C.sample_dir}"
          process("fork") do
            env "PID_NAME" => "#{C.p3_pid}"
            pid_file "#{C.p3_pid}"
            start_command "ruby forking.rb start"
            stop_command "kill -9 {PID}" # SPECIALLY here wrong command for kill parent
            stdall "trash.log"
            monitor_children { childs_update_period 3.seconds }

            trigger :transition, :event => [:stopped, :crashed], :do => ->{
              process.childs.pmap { |pid, c| c.stop }
            }
          end
        end
      D

      with_temp_file(cfg){ |f| @c.load(f) }
      sleep 5
      @process = @c.process_by_name("fork")
      @process.wait_for_condition(15, 0.3) { @process.childs.size == 3 }
      @process.state_name.should == :up
      @pid = @process.pid
      @chpids = @process.childs.keys
    end

    it "when process crashed it should kill all chils too" do
      @process.childs.size.should == 3
      Eye::System.pid_alive?(@pid).should == true
      @chpids.each { |pid| Eye::System.pid_alive?(pid).should == true }

      die_process!(@process.pid)
      sleep 10

      Eye::System.pid_alive?(@pid).should == false
      @chpids.each { |pid| Eye::System.pid_alive?(pid).should == false }

      @process.state_name.should == :up

      @pids = @process.childs.keys # to ensure spec kill them
      @process.childs.size.should == 3
    end

    it "when process restarted should kill childs too" do
      @process.childs.size.should == 3
      Eye::System.pid_alive?(@pid).should == true
      @chpids.each { |pid| Eye::System.pid_alive?(pid).should == true }

      @process.schedule :restart
      sleep 10

      Eye::System.pid_alive?(@pid).should == false
      @chpids.each { |pid| Eye::System.pid_alive?(pid).should == false }

      @process.state_name.should == :up

      @pids = @process.childs.keys # to ensure spec kill them
      @process.childs.size.should == 3
    end
  end

  describe "catch errors" do
    it "catch just error in do" do
      cfg = <<-D
        Eye.application("bla") do
          working_dir "#{C.sample_dir}"
          process("1") do
            pid_file "#{C.p1_pid}"
            start_command "sleep 30"
            daemonize true
            trigger :transition1, :to => :up, :do => ->{ info "some"; 1/0 }
          end
        end
      D

      with_temp_file(cfg){ |f| @c.load(f) }
      @process = @c.process_by_name("1")
      @process.wait_for_condition(3, 0.3) { @process.state_name == :up }

      sleep 2
      @process.alive?.should == true
      @process.state_name.should == :up
    end

    it "catch just error in do with NoMethodError" do
      cfg = <<-D
        Eye.application("bla") do
          working_dir "#{C.sample_dir}"
          process("1") do
            pid_file "#{C.p1_pid}"
            start_command "sleep 30"
            daemonize true
            trigger :transition1, :to => :up, :do => ->{ info "some"; wtf? }
          end
        end
      D

      with_temp_file(cfg){ |f| @c.load(f) }
      @process = @c.process_by_name("1")
      @process.wait_for_condition(3, 0.3) { @process.state_name == :up }

      sleep 2
      @process.alive?.should == true
      @process.state_name.should == :up
    end

    it "catch error when unknown symbol" do
      cfg = <<-D
        Eye.application("bla") do
          working_dir "#{C.sample_dir}"
          process("1") do
            pid_file "#{C.p1_pid}"
            start_command "sleep 30"
            daemonize true
            trigger :transition1, :to => :up, :do => :sdfsdfasdfsdfdd
          end
        end
      D

      with_temp_file(cfg){ |f| @c.load(f) }
      @process = @c.process_by_name("1")
      @process.wait_for_condition(3, 0.3) { @process.state_name == :up }

      sleep 2
      @process.alive?.should == true
      @process.state_name.should == :up
    end
  end

end