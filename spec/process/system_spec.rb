require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Process::System" do
  before :each do
    @process = Eye::Process.new(C.p1)
  end

  it "load_pid_from_file" do
    File.open(@process[:pid_file_ex], 'w'){|f| f.write("asdf") }
    @process.load_pid_from_file.should == nil

    File.open(@process[:pid_file_ex], 'w'){|f| f.write(12345) }
    @process.load_pid_from_file.should == 12345

    FileUtils.rm(@process[:pid_file_ex]) rescue nil
    @process.load_pid_from_file.should == nil
  end

  it "failsafe_load_pid" do
    File.open(@process[:pid_file_ex], 'w'){|f| f.write("asdf") }
    @process.failsafe_load_pid.should == nil

    File.open(@process[:pid_file_ex], 'w'){|f| f.write(12345) }
    @process.failsafe_load_pid.should == 12345

    FileUtils.rm(@process[:pid_file_ex]) rescue nil
    @process.failsafe_load_pid.should == nil
  end

  it "set_pid_from_file" do
    File.open(@process[:pid_file_ex], 'w'){|f| f.write(12345) }
    @process.set_pid_from_file
    @process.pid.should == 12345
    @process.pid = nil
  end

  it "save_pid_to_file" do
    @process.pid = 123456789
    @process.save_pid_to_file
    File.read(@process[:pid_file_ex]).to_i.should == 123456789
  end

  it "failsafe_save_pid ok case" do
    @process.pid = 123456789
    @process.failsafe_save_pid.should == true
    File.read(@process[:pid_file_ex]).to_i.should == 123456789
  end

  it "failsafe_save_pid bad case" do
    @process.config[:pid_file_ex] = "/asdf/adf/asd/fs/dfs/das/df.1"
    @process.pid = 123456789
    @process.failsafe_save_pid.should == false
  end

  it "clear_pid_file" do
    @process.pid = 123456789
    @process.save_pid_to_file
    File.read(@process[:pid_file_ex]).to_i.should == 123456789

    @process.clear_pid_file.should == true
    File.exists?(@process[:pid_file_ex]).should == false
  end

  it "process_really_running?" do
    @process.pid = $$
    @process.process_really_running?.should == true

    @process.pid = nil
    @process.process_really_running?.should == false

    @process.pid = -123434
    @process.process_really_running?.should == false
  end

  it "send_signal ok" do
    mock(Eye::System).send_signal(@process.pid, :TERM){ {:result => :ok} }
    @process.send_signal(:TERM).should == true
  end

  it "send_signal not ok" do
    mock(Eye::System).send_signal(@process.pid, :TERM){ {:error => Exception.new('bla')} }
    @process.send_signal(:TERM).should == false
  end

  it "pid_file_ctime" do
    File.open(@process[:pid_file_ex], 'w'){|f| f.write("asdf") }
    sleep 1
    (Time.now - @process.pid_file_ctime).should > 1.second

    @process.clear_pid_file
    (Time.now - @process.pid_file_ctime).should < 0.1.second
  end

  [C.p1, C.p2].each do |cfg|
    it "blocking execute should not block process actor mailbox #{cfg[:name]}" do
      @process = Eye::Process.new(cfg.merge(:start_command => "sleep 5", :start_timeout => 10.seconds))
      should_spend(1) do
        @process.async.start
        sleep 1

        # here mailbox should anwser without blocks
        @process.name.should == cfg[:name]
      end
    end
  end

  it "execute_sync helper" do
    filename = "asdfasdfsd.tmp"
    full_filename = C.working_dir + "/" + filename
    FileUtils.rm(full_filename) rescue nil
    File.exists?(full_filename).should == false
    res = @process.execute_sync("touch #{filename}")
    File.exists?(full_filename).should == true
    FileUtils.rm(full_filename) rescue nil
    res[:exitstatus].should == 0
  end

  it "execute_async helper" do
    filename = "asdfasdfsd.tmp"
    full_filename = C.working_dir + "/" + filename
    FileUtils.rm(full_filename) rescue nil
    File.exists?(full_filename).should == false
    res = @process.execute_async("touch #{filename}")
    sleep 0.2
    File.exists?(full_filename).should == true
    FileUtils.rm(full_filename) rescue nil
    res[:exitstatus].should == 0
  end

  context "#wait_for_condition" do
    subject{ Eye::Process.new(C.p1) }

    it "success" do
      should_spend(0) do
        subject.wait_for_condition(1){ 15 }.should == 15
      end
    end

    it "success with sleep" do
      should_spend(0.3) do
        subject.wait_for_condition(1){ sleep 0.3; :a }.should == :a
      end
    end

    # it "fail by timeout" do
    #   should_spend(1) do
    #     subject.wait_for_condition(1){ sleep 4; true }.should == false
    #   end
    # end

    it "fail with bad result" do
      should_spend(1) do
        subject.wait_for_condition(1){ nil }.should == false
      end
    end
  end


end
