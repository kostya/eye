module C
  extend self

  def working_dir
    sample_dir
  end

  def sample_dir
    File.expand_path(File.join(File.dirname(__FILE__), %w{.. example}))
  end

  def log_name
    "1111#{process_id}.log"
  end

  def [](c)
    p[c]
  end

  def p
    {1 => p1, 2 => p2, 3 => p3, 4 => p4, 5 => p5}
  end

  def base
    {
      :environment => {"ENV1" => "SUPER"},
      :working_dir => sample_dir,
      :application => "main",
      :group => "default",
      :name => "base",
      :stdout => sample_dir + "/#{log_name}",
      :stderr => sample_dir + "/#{log_name}",
      :check_alive_period => 1.seconds,
      :start_timeout => 5.seconds,
      :stop_timeout => 2.seconds,
    }
  end

  def just_pid
    sample_dir + "/aaa#{process_id}.pid"
  end

  # eye daemonize process
  def p1_pid
    "1#{process_id}.pid"
  end

  def p1_lock
    sample_dir + "/lock1#{process_id}.lock"
  end

  def p1
    base.merge(
      :pid_file => sample_dir + "/#{p1_pid}",
      :name => "blocking process",
      :start_command => "ruby sample.rb",
      :daemonize => true
    )
  end

  # self daemonized process
  def p2_pid
    "2#{process_id}.pid"
  end

  def p2_lock
    sample_dir + "/lock2#{process_id}.lock"
  end

  def p2
    base.merge(
      :pid_file => sample_dir + "/#{p2_pid}",
      :name => "self daemonized process",
      :start_command => "ruby sample.rb -d --pid #{p2_pid} --log #{log_name}",
    )
  end

  # forking example
  def p3_pid
    "forking#{process_id}.pid"
  end

  def p3
    base.merge(
      :environment => {"PID_NAME" => p3_pid},
      :name => "forking",
      :start_command => "ruby forking.rb start",
      :stop_command => "ruby forking.rb stop",
      :pid_file => sample_dir + "/" + p3_pid,
      :children_update_period => Eye::SystemResources::cache.expire + 1,
      :stop_timeout => 5.seconds,
      :start_timeout => 15.seconds,
      :notify => { "abcd" => :warn }
    )
  end

  # event machine
  def p4_ports
    [31231 + process_id * 3, 31232 + process_id * 3, 31233 + process_id * 3]
  end

  def p4_sock
    "/tmp/em_test_sock_spec#{process_id}"
  end

  def p4
    base.merge(
      :pid_file => "#{sample_dir}/em#{process_id}.pid",
      :name => "em",
      :start_command => "ruby em.rb #{p4_ports[0]} #{p4_ports[1]} #{p4_sock} #{p4_ports[2]}",
      :daemonize => true,
      :start_grace => 3.5,
      :stop_grace => 0.7
    )
  end

  # thin
  def p5_port
    31334 + process_id
  end

  def p5_pid
    "thin#{process_id}.pid"
  end

  def p5
    base.merge(
      :pid_file => sample_dir + "/" + p5_pid,
      :name => "thin",
      :start_command => "bundle exec thin start -R thin.ru -p #{p5_port} -l thin.log -P #{p5_pid}",
      :daemonize => true,
    )
  end

  def p6_word
    '1234_my_sleppie'
  end

  def p6
    p1.merge(:start_command => "sh -c 'sleep 10 && echo #{p6_word}'", :use_leaf_child => true, :start_grace => 0.5.seconds)
  end

  def tmp_file
    C.sample_dir + "/1#{process_id}.tmp"
  end

  def check_mem(a = {})
    {:memory => {:type => :memory, :every => 2.seconds, :below => 100.megabytes, :times => [3,5]}.merge(a)}
  end

  def check_cpu(a = {})
    {:cpu => {:type => :cpu, :every => 2.seconds, :below => 80, :times => [4,5]}.merge(a)}
  end

  def check_ctime(a = {})
    {:ctime => {:type => :ctime, :every => 2, :file => log_name, :times => [3,5]}.merge(a)}
  end

  def check_fsize(a = {})
    {:fsize => {:type => :fsize, :every => 2, :file => log_name, :times => [3,5]}.merge(a)}
  end

  def check_http(a = {})
    {:http => {
      :type => :http, :every => 2, :times => 1,
      :url => "http://localhost:3000/bla", :kind => :sucess,
      :pattern => /OK/, :timeout => 3.seconds
    }.merge(a)
    }
  end

  def check_sock(a = {})
    {:socket => {:type => :socket, :every => 5.seconds,
     :times => 1, :addr => "tcp://127.0.0.1:#{p4_ports[0]}", :send_data => "ping",
     :expect_data => /pong/, :timeout => 2}.merge(a)
    }
  end

  def check_children_count(a = {})
    {:children_count => {:type => :children_count, :every => 2.seconds, :below => 5, :times => 2}.merge(a)}
  end

  def check_children_memory(a = {})
    {:children_memory => {:type => :children_memory, :every => 2.seconds, :below => 50.megabytes, :times => 2}.merge(a)}
  end

  def flapping(a = {})
    {:flapping => { :type => :flapping, :times => 2, :within => 10.seconds }.merge(a)}
  end

  def restart_sync
    {:restart => {:action => :restart, :type => :sync, :grace => 5}}
  end

  def restart_async
    {:restart => {:action => :restart, :type => :async, :grace => 5}}
  end

  def socket_path
    File.join(sample_dir, "sock1#{process_id}")
  end

end

class TrapError
  include Celluloid

  trap_exit :actor_died

  def actor_died(actor, reason)
    if reason
      $logger.error "Actor Died! #{actor.inspect} has died because of a #{reason.inspect}"
    end
    #$logger.error "#{reason.message}"
    #$logger.error "#{reason.backtrace * "\n"}"
  end
end

def process(cfg)
  p = Eye::Process.new(cfg)
  @trap = TrapError.new
  @trap.link(p)
  p
end

def start_ok_process(cfg = C.p1)
  @process = process(cfg)
  @process.start
  sleep 0.2

  @process.process_really_running?.should == true
  @process.pid.should > 0
  @process.watchers.keys.should == [:check_alive, :check_identity] if !cfg[:check_alive] == false
  @process.state_name.should == :up
  @pid = @process.pid
  Eye::System.pid_alive?(@pid).should == true

  @process
end

def die_process!(pid, signal = :kill, int = 0.3)
  Eye::System.send_signal(pid, signal)
  sleep int.to_f
  Eye::System.pid_alive?(pid).should == false
end

def change_ctime(filename, t = Time.now, now = false)
  if now
    system "touch #{filename}"
  else
    system "touch -t #{t.strftime('%Y%m%d%H%M')} #{filename}"
  end
end

require_relative 'rr_celluloid'

def new_controller(filename)
  Eye::Controller.new.tap do |c|
    c.load(filename)
  end
end

RSpec::Matchers.define :contain_only do |*expected|
  match do |actual|
    actual.uniq.sort == expected.flatten.sort
  end
end

RSpec::Matchers.define :seq do |*expected|
  match do |actual|
    actual.join(',').include?(expected.flatten.join(','))
  end
end
