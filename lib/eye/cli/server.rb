module Eye::Cli::Server
private

  def server_started?
    _cmd(:ping) == :pong
  end

  def loader_path
    filename = File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. .. bin loader_eye]))
    File.exists?(filename) ? filename : nil
  end

  def ruby_path
    require 'rbconfig'
    RbConfig::CONFIG['bindir'] + "/ruby"
  end

  def ensure_loader_path
    unless loader_path
      error! "start monitoring needs to run under ruby with installed gem 'eye'"
    end
  end

  def server_start_foregraund(conf = nil)
    ensure_loader_path
    Eye::Settings.ensure_eye_dir

    if server_started?
      _cmd(:quit) && sleep(1) # stop previous server
    end

    args = []
    args += ['-c', conf] if conf
    args += ['-l', 'stdout']

    Process.exec(ruby_path, loader_path, *args)
  end

  def server_start(configs)
    ensure_loader_path
    Eye::Settings.ensure_eye_dir

    ensure_stop_previous_server

    args = []
    opts = {:out => '/dev/null', :err => '/dev/null', :in => '/dev/null',
            :chdir => '/', :pgroup => true}

    pid = Process.spawn(ruby_path, loader_path, *args, opts)
    Process.detach(pid)
    File.open(Eye::Settings.pid_path, 'w'){|f| f.write(pid) }

    unless wait_server
      error! "server not runned in 15 seconds, something crazy wrong"
    end

    configs.unshift(Eye::Settings.eyeconfig) if File.exists?(Eye::Settings.eyeconfig)

    if !configs.empty?
      say_load_result cmd(:load, *configs), :started => true
    else
      say "started!", :green
    end
  end

  def ensure_stop_previous_server
    Eye::Settings.ensure_eye_dir
    pid = File.read(Eye::Settings.pid_path).to_i rescue nil
    if pid
      Process.kill(9, pid) rescue nil
    end
    File.delete(Eye::Settings.pid_path) rescue nil
    true
  end

  def wait_server(timeout = 15)
    Timeout.timeout(timeout) do
      sleep 0.3 while !server_started?
    end
    true
  rescue Timeout::Error
    false
  end

end