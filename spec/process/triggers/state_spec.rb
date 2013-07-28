require File.dirname(__FILE__) + '/../../spec_helper'

describe "Trigger State" do
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
            trigger :state, :to => :down, :do => ->{ File.delete("#{C.tmp_file}") }
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
            trigger :state, :event => :crashed, :do => ->{ File.delete("#{C.tmp_file}") }
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

end