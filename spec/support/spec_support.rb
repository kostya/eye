module C
  extend self

  def sample_dir
    File.expand_path(File.join(File.dirname(__FILE__), %w{.. example}))
  end
  
  def pid_name
    "1.pid"
  end
  
  def log_name
    "1111.log"
  end

  def base
    {
      :environment => {"ENV1" => "SUPER"},
      :working_dir => sample_dir,
      :application => "main",
      :group => "default",
      :name => "base",
      :pid_file => sample_dir + "/#{pid_name}",
      :stdout => sample_dir + "/#{log_name}",
      :stderr => sample_dir + "/#{log_name}",
      :check_alive_period => 1.seconds,
      :start_timeout => 5.seconds,
      :stop_timeout => 2.seconds,      
    }
  end

  # eye daemonize process
  def p1 
    base.merge(
      :name => "blocking process",
      :start_command => "ruby sample.rb",
      :daemonize => true
    )
  end

  # self daemonized process
  def p2
    base.merge(
      :name => "self daemonized process",
      :start_command => "ruby sample.rb -d --pid #{pid_name} --log #{log_name}",
    )
  end

  # forking example
  def p3
    base.merge(
      :name => "forking",
      :start_command => "ruby forking.rb start",
      :stop_command => "ruby forking.rb stop",
      :pid_file => "forking.pid",
      :childs_update_period => Eye::SystemResources::PsAxActor::UPDATE_INTERVAL + 1,
      :stop_timeout => 5.seconds,
      :start_timeout => 15.seconds
    )
  end

  # event machine
  def p4
    base.merge(
      :pid_file => "em.pid",
      :name => "em",
      :start_command => "ruby em.rb",
      :daemonize => true,
      :start_grace => 3.5,
      :stop_grace => 0.5
    )
  end

  # thin
  def p5
    base.merge(
      :pid_file => "thin.pid",
      :name => "thin",
      :start_command => "bundle exec thin start -R thin.ru -p 33233 -l thin.log -P thin.pid",
      :daemonize => true,
    )
  end

  def check_mem(a = {})
    {:memory => {:type => :memory, :every => 2.seconds, :below => 100.megabytes, :times => [3,5]}.merge(a)}
  end

  def check_cpu(a = {})
    {:cpu => {:type => :cpu, :every => 2.seconds, :below => 80, :times => [4,5]}.merge(a)}
  end

  def check_ctime(a = {})
    {:ctime => {:type => :ctime, :every => 2, :file => sample_dir + "/#{log_name}", :times => [3,5]}.merge(a)}
  end

  def check_fsize(a = {})
    {:fsize => {:type => :fsize, :every => 2, :file => sample_dir + "/#{log_name}", :times => [3,5]}.merge(a)}
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
     :times => 1, :addr => 'tcp://127.0.0.1:33231', :send_data => "ping",
     :expect_data => /pong/, :timeout => 2}.merge(a)
    }
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
    File.join(sample_dir, 'sock1')
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

  @process.process_realy_running?.should == true
  @process.pid.should > 0
  @process.watchers.keys.should == [:check_alive] if !cfg[:check_alive] == false
  @process.state_name.should == :up
  @pid = @process.pid
  Eye::System.pid_alive?(@pid).should == true

  @process
end

def die_process!(pid, signal = :term, int = 0.2)
  Eye::System.send_signal(pid, signal)
  sleep int.to_f
  Eye::System.pid_alive?(pid).should == false
end

def ensure_kill_samples
  `ps aux | grep 'ruby sample.rb' | awk '{print $2}' | xargs kill -2 2>/dev/null` rescue nil
end

require_relative 'rr_celluloid'