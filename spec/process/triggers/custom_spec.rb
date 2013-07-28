require File.dirname(__FILE__) + '/../../spec_helper'

describe "Trigger Custom" do
  before :each do
    @c = Eye::Controller.new
  end

  describe "delete file" do
    before :each do
      cfg = <<-D
class DeleteFile < Eye::Trigger::Custom
  param :file, [String], true
  param :on, [Symbol]

  def check(transition)
    if transition.to_name == on
      info "rm \#{file}"
      File.delete(file)
    end
  end
end

Eye.application("bla") do
  working_dir "#{C.sample_dir}"
  process("1") do
    pid_file "#{C.p1_pid}"
    start_command "sleep 30"
    daemonize true
    trigger :delete_file, :file => "#{C.tmp_file}", :on => :down
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
class DeleteFileEvent < Eye::Trigger::Custom
  param :file, [String], true
  param :on, [Symbol]

  def check(transition)
    if transition.event == on
      info "rm \#{file}"
      File.delete(file)
    end
  end
end

Eye.application("bla") do
  working_dir "#{C.sample_dir}"
  process("1") do
    pid_file "#{C.p1_pid}"
    start_command "sleep 30"
    daemonize true
    trigger :delete_file_event, :file => "#{C.tmp_file}", :on => :crashed
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