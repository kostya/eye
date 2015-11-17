# encoding: utf-8

module Eye::Cli::Server

private

  def server_started?
    _cmd(:ping) == :pong
  end

  def loader_path
    filename = File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. .. bin loader_eye]))
    File.exist?(filename) ? filename : nil
  end

  def ruby_path
    RbConfig.ruby
  end

  def ensure_loader_path
    unless loader_path
      error! "start monitoring needs to run under ruby with installed gem 'eye'"
    end
  end

  def server_start_foreground(conf = nil)
    ensure_loader_path
    Eye::Local.ensure_eye_dir

    args = []
    args += ['--config', conf] if conf
    args += ['--logger', 'stdout']
    args += ['--stop_all']
    if Eye::Local.local_runner
      args += ['--dir', Eye::Local.dir]
      if !conf && Eye::Local.eyefile
        args += ['--config', Eye::Local.eyefile]
      end
    end

    Process.exec(ruby_path, loader_path, *args)
  end

  def server_start(configs)
    ensure_loader_path
    Eye::Local.ensure_eye_dir

    ensure_stop_previous_server

    args = []
    args += ['--dir', Eye::Local.dir] if Eye::Local.local_runner

    chdir = if Eye::Local.local_runner
      Eye::Local.home
    else
      '/'
    end

    opts = { out: '/dev/null', err: '/dev/null', in: '/dev/null',
             chdir: chdir, pgroup: true }

    pid = Process.spawn(ruby_path, loader_path, *args, opts)
    Process.detach(pid)
    File.open(Eye::Local.pid_path, 'w') { |f| f.write(pid) }

    unless wait_server
      error! 'server has not started in 15 seconds, something is very wrong'
    end

    configs.unshift(Eye::Local.global_eyeconfig) if File.exist?(Eye::Local.global_eyeconfig)
    configs.unshift(Eye::Local.eyeconfig) if File.exist?(Eye::Local.eyeconfig)
    configs << Eye::Local.eyefile if Eye::Local.local_runner && Eye::Local.eyefile

    say "Eye started! ㋡ (#{Eye::Local.home})", :green

    if configs.any?
      say_load_result cmd(:load, *configs)
    end
  end

  def ensure_stop_previous_server
    Eye::Local.ensure_eye_dir
    pid = File.read(Eye::Local.pid_path).to_i rescue nil
    Process.kill(9, pid) rescue nil if pid
    File.delete(Eye::Local.pid_path) rescue nil
    true
  end

  def wait_server(timeout = 15)
    Timeout.timeout(timeout) do
      sleep 0.3 until server_started?
    end
    true
  rescue Timeout::Error
    false
  end

end
