require File.dirname(__FILE__) + '/spec_helper'

describe "Eye::System" do

  it "pid_alive?" do
    Eye::System.pid_alive?($$).should == true
    Eye::System.pid_alive?(123456).should == false    
    Eye::System.pid_alive?(-122).should == false    
    Eye::System.pid_alive?(nil).should == false
  end

  it "check_pid_alive" do
    Eye::System.check_pid_alive($$).should == {:result => true}
    Eye::System.check_pid_alive(123456)[:error].class.should == Errno::ESRCH
    Eye::System.check_pid_alive(-122)[:error].class.should == Errno::ESRCH
    Eye::System.check_pid_alive(nil).should == {:result => false}
  end

  it "ps_aux" do
    h = Eye::System.ps_aux
    h.size.should > 10
    x = h[$$]
    x.should be
    x.is_a?(Hash).should be_true
    x[:ppid].should > 1 # parent pid
    x[:cpu].should >= 0 # proc
    x[:rss].should > 1000 # memory
    x[:start_time].length.should >= 5
  end

  it "prepare env" do
    Eye::System.send(:prepare_env, {}).should include({})
    Eye::System.send(:prepare_env, {:environment => {'A' => 'B'}}).should include({'A' => 'B'})    
    Eye::System.send(:prepare_env, {:environment => {'A' => 'B'}, :working_dir => "/tmp"}).should include({'A' => 'B', 'PWD' => '/tmp'})

    r = Eye::System.send(:prepare_env, {:environment => {'A' => [], 'B' => {}, 'C' => nil, 'D' => 1, 'E' => '2'}})
    r['A'].should == '[]'
    r['B'].should == '{}'
    r['C'].should == nil
    r['D'].should == '1'
    r['E'].should == '2'
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

    it "should add LANG env varible" do
      mock(Process).spawn({"BLA"=>"1", "LANG"=>ENV_LANG}, 'echo', 'some', anything)
      stub(Process).detach

      @pid = Eye::System.daemonize("echo 'some'", {:stdout => @log, :environment => {"BLA" => "1"}})[:pid]
    end
  end

  describe "execute" do
    it "sleep and exit" do
      should_spend(1, 0.2) do
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
