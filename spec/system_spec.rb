require File.dirname(__FILE__) + '/spec_helper'

describe "Eye::System" do

  it "pid_alive?" do
    Eye::System.pid_alive?($$).should == true
    Eye::System.pid_alive?(123456).should == false
    Eye::System.pid_alive?(-122).should == false
    Eye::System.pid_alive?(nil).should == false
  end

  it "check_pid_alive" do
    Eye::System.check_pid_alive($$).should == {:result => 1}
    Eye::System.check_pid_alive(123456)[:error].class.should == Errno::ESRCH
    Eye::System.check_pid_alive(-122)[:error].should be
    Eye::System.check_pid_alive(nil).should == {:result => false}
  end

  it "prepare env" do
    Eye::System.send(:prepare_env, {}).should eq({})
    Eye::System.send(:prepare_env, {:environment => {'A' => 'B'}}).should eq({'A' => 'B'})
    Eye::System.send(:prepare_env, {:environment => {'A' => 'B'}, :working_dir => "/tmp"}).should eq({'A' => 'B'})

    r = Eye::System.send(:prepare_env, {:environment => {'A' => [], 'B' => {}, 'C' => nil, 'D' => 1, 'E' => '2'}})
    r.should eq(
      'A' => '[]',
      'B' => '{}',
      'C' => nil,
      'D' => '1',
      'E' => '2'
    )
  end

  it "set spawn_options" do
    stub(Eye::Local).root? { true }
    Eye::System.send(:spawn_options, {}).should == {:pgroup => true, :chdir => "/"}
    Eye::System.send(:spawn_options, {:working_dir => "/tmp"}).should include(:chdir => "/tmp")
    Eye::System.send(:spawn_options, {:stdout => "/tmp/1", :stderr => "/tmp/2"}).should include(:out => ["/tmp/1", 'a'], :err => ["/tmp/2", 'a'])
    Eye::System.send(:spawn_options, {:clear_env => true}).should include({:unsetenv_others => true})

    # root user exists
    mock(Etc).getpwnam('root') { OpenStruct.new(:uid => 0) }
    # user asdf does not exist
    stub(Etc).getpwnam('asdf') { raise "can't find user for asdf" }
    # However, group asdf does exist
    mock(Etc).getgrnam('asdf') { OpenStruct.new(:gid => 1234) }
    Eye::System.send(:spawn_options, {:uid => "root", :gid => "asdf"}).should include({:uid => 0, :gid => 1234})
  end

  describe "daemonize" do
    it "daemonize default" do
      @pid = Eye::System.daemonize("ruby sample.rb", {:environment => {"ENV1" => "SECRET1", 'BLA' => {}},
        :working_dir => C.p1[:working_dir], :stdout => @log})[:pid]

      @pid.should > 0

      # process should be alive
      Eye::System.pid_alive?(@pid).should == true

      sleep 4

      # should capture log
      data = File.read(@log)
      data.should include("SECRET1")
      data.should include("- tick")
    end

    it "daemonize empty" do
      @pid = Eye::System.daemonize("ruby sample.rb", {:working_dir => C.p1[:working_dir]})[:pid]

      # process should be alive
      Eye::System.pid_alive?(@pid).should == true
    end

    it "daemonize empty" do
      @pid = Eye::System.daemonize("echo 'some'", {:stdout => @log})[:pid]

      sleep 0.3

      data = File.read(@log)
      data.should == "some\n"
    end

    it "should provide all to spawn correctly" do
      args = [{"A"=>"1", "B"=>nil, "C"=>"3"}, "echo", "1",
        {:pgroup=>true, :chdir=>"/", :out=>["/tmp/1", "a"], :err=>["/tmp/2", "a"]}]
      mock(Process).spawn(*args){ 1234555 }
      mock(Process).detach( 1234555 )
      Eye::System::daemonize("echo 1", :environment => {'A' => 1, 'B' => nil, 'C' => 3},
        :stdout => "/tmp/1", :stderr => "/tmp/2")
    end
  end

  describe "execute" do
    it "sleep and exit" do
      should_spend(1, 0.3) do
        Eye::System.execute("sleep 1")
      end
    end
  end

  describe "send signal" do
    it "send_signal to spec" do
      Eye::System.send_signal($$, 0)[:result].should == :ok
    end

    it "send_signal to unexisted process" do
      res = Eye::System.send_signal(-12234)
      res[:status].should == nil
      res[:error].message.should include("No such process")
    end

    it "send_signal to daemon" do
      @pid = Eye::System.daemonize("ruby sample.rb", {:working_dir => C.p1[:working_dir]})[:pid]

      # process should be alive
      Eye::System.pid_alive?(@pid).should == true

      Eye::System.send_signal(@pid, :term)[:result].should == :ok
      sleep 0.2

      Eye::System.pid_alive?(@pid).should == false
    end

    it "catch signal in fork" do
      @pid = Eye::System.daemonize("ruby sample.rb", {:working_dir => C.p1[:working_dir],
        :stdout => @log})[:pid]

      sleep 4

      Eye::System.send_signal(@pid, :usr1)[:result].should == :ok

      sleep 0.5

      data = File.read(@log)
      data.should include("USR1 sig")
    end

    it "signals transformation" do
      mock(Process).kill('USR1', 123)
      Eye::System.send_signal(123, :usr1)

      mock(Process).kill('KILL', 123)
      Eye::System.send_signal(123, :KILL)

      mock(Process).kill('USR1', 123)
      Eye::System.send_signal(123, 'usr1')

      mock(Process).kill('KILL', 123)
      Eye::System.send_signal(123, 'KILL')

      mock(Process).kill(9, 123)
      Eye::System.send_signal(123, 9)

      mock(Process).kill(9, 123)
      Eye::System.send_signal(123, '9')

      mock(Process).kill(9, 123)
      Eye::System.send_signal(123, '-9')

      mock(Process).kill(9, 123)
      Eye::System.send_signal(123, -9)

      mock(Process).kill(0, 123)
      Eye::System.send_signal(123, '0')
    end
  end

  it "normalized_file" do
    Eye::System.normalized_file("/tmp/1.rb").should == "/tmp/1.rb"
    Eye::System.normalized_file("/tmp/1.rb", '/usr').should == "/tmp/1.rb"

    Eye::System.normalized_file("tmp/1.rb").should == Dir.getwd + "/tmp/1.rb"
    Eye::System.normalized_file("tmp/1.rb", '/usr').should == "/usr/tmp/1.rb"

    Eye::System.normalized_file("./tmp/1.rb").should == Dir.getwd + "/tmp/1.rb"
    Eye::System.normalized_file("./tmp/1.rb", '/usr/').should == "/usr/tmp/1.rb"

    Eye::System.normalized_file("../tmp/1.rb", '/usr/').should == "/tmp/1.rb"
  end

end
