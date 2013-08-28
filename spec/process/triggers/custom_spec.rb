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

  describe "multiply custom" do
    before :each do
      cfg = <<-D
class DeleteFileEventA2 < Eye::Trigger::Custom
  param :file, [String], true
  param :on, [Symbol]
  param :what, [Fixnum]

  def check(transition)
    if transition.to_name == on
      if what == 2
        info "rm \#{file}"
        File.delete(file)
      else
        info "touch \#{file}"
        File.open(file, 'w')
      end
    end
  end
end

Eye.application("bla") do
  working_dir "#{C.sample_dir}"
  process("1") do
    pid_file "#{C.p1_pid}"
    start_command "sleep 30"
    daemonize true
    trigger :delete_file_event_a2_1, :file => "#{C.tmp_file}", :on => :up, :what => 1
    trigger :delete_file_event_a2_2, :file => "#{C.tmp_file}", :on => :down, :what => 2
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

  describe "catch exceptions" do
    before :each do
      @app = <<-D
        Eye.application("bla") do
          working_dir "#{C.sample_dir}"
          process("1") do
            pid_file "#{C.p1_pid}"
            start_command "sleep 30"
            daemonize true
            trigger :cust2
          end
        end
      D
    end

    it "when raised in initialize" do
      conf = <<-D
        class Cust2 < Eye::Trigger::Custom
          def initialize(*a); super; raise :jop; end
          def check(t); end
        end
        #{@app}
      D
      with_temp_file(conf){ |f| @c.load(f) }
      @process = @c.process_by_name("1")
      @process.wait_for_condition(3, 0.3) { @process.state_name == :up }

      sleep 2
      @process.alive?.should == true
      @process.state_name.should == :up
    end

    it "when raised in check" do
      conf = <<-D
        class Cust2 < Eye::Trigger::Custom
          def initialize(*a); super; end
          def check(t); 1/0; end
        end
        #{@app}
      D
      with_temp_file(conf){ |f| @c.load(f) }
      @process = @c.process_by_name("1")
      @process.wait_for_condition(3, 0.3) { @process.state_name == :up }

      sleep 2
      @process.alive?.should == true
      @process.state_name.should == :up
    end

    it "when raised in check NoMethodError" do
      conf = <<-D
        class Cust2 < Eye::Trigger::Custom
          def initialize(*a); super; end
          def check(t); jop?; end
        end
        #{@app}
      D
      with_temp_file(conf){ |f| @c.load(f) }
      @process = @c.process_by_name("1")
      @process.wait_for_condition(3, 0.3) { @process.state_name == :up }

      sleep 2
      @process.alive?.should == true
      @process.state_name.should == :up
    end
  end

end