require File.dirname(__FILE__) + '/../spec_helper'

[C.p1, C.p2].each do |cfg|
  describe "Process Pid Managment '#{cfg[:name]}'" do

    it "crashed of process should remove pid_file for daemonize only" do
      start_ok_process(cfg)
      die_process!(@pid)

      mock(@process).start # stub start for clean test

      sleep 4

      if cfg[:daemonize]
        @process.load_pid_from_file.should == nil
      else
        @process.load_pid_from_file.should == @pid
      end
    end

    it "someone remove pid_file. should rewrite" do
      start_ok_process(cfg)
      old_pid = @pid
      File.exists?(cfg[:pid_file]).should == true

      FileUtils.rm(cfg[:pid_file]) # someone removes it (bad man)
      File.exists?(cfg[:pid_file]).should == false

      sleep 5 # wait until monitor understand it

      File.exists?(cfg[:pid_file]).should == true
      @process.pid.should == old_pid
      @process.load_pid_from_file.should == @process.pid
      @process.state_name.should == :up
    end

    it "someone rewrite pid_file. should rewrite for daemonize only" do
      start_ok_process(cfg)
      old_pid = @pid
      @process.load_pid_from_file.should == @pid

      File.open(cfg[:pid_file], 'w'){|f| f.write(99999) }
      @process.load_pid_from_file.should == 99999

      sleep 5 # wait until monitor understand it

      if cfg[:daemonize]
        @process.load_pid_from_file.should == @pid
      else
        @process.load_pid_from_file.should == 99999
      end

      @process.pid.should == old_pid
      @process.state_name.should == :up
    end

    it "someone rewrite pid_file. and ctime > limit, should rewrite for both" do
      start_ok_process(cfg.merge(:revert_fuckup_pidfile_grace => 3.seconds))
      old_pid = @pid
      @process.load_pid_from_file.should == @pid

      File.open(cfg[:pid_file], 'w'){|f| f.write(99999) }
      @process.load_pid_from_file.should == 99999

      sleep 8 # wait until monitor understand it

      @process.load_pid_from_file.should == @pid

      @process.pid.should == old_pid
      @process.state_name.should == :up
    end

  end
end
