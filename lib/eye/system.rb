require 'shellwords'
require 'pathname'
require 'etc'

module Eye::System
  class << self
    # Check that pid realy exits
    # very fast
    # return result hash
    def check_pid_alive(pid)
      res = if pid
        ::Process.kill(0, pid)
      else
        false
      end

      {:result => res}
    rescue => ex
      {:error => ex}
    end

    # Check that pid realy exits
    # very fast
    # return true/false
    def pid_alive?(pid)
      res = check_pid_alive(pid)
      !!res[:result]
    end

    # Send signal to process (uses for kill)
    # code: TERM(15), KILL(9), QUIT(3), ...
    def send_signal(pid, code = :TERM)
      code = 0 if code == '0'
      if code.to_s.to_i != 0
        code = code.to_i
        code = -code if code < 0
      end
      code = code.to_s.upcase if code.is_a?(String) || code.is_a?(Symbol)

      if pid
        ::Process.kill(code, pid)
        {:result => :ok}
      else
        {:error => Exception.new('no_pid')}
      end

    rescue => ex
      {:error => ex}
    end

    # Daemonize cmd, and detach
    # options:
    #   :pid_file
    #   :working_dir
    #   :environment
    #   :stdin, :stdout, :stderr
    def daemonize(cmd, cfg = {})
      opts = spawn_options(cfg)
      pid  = Process::spawn(prepare_env(cfg), *Shellwords.shellwords(cmd), opts)
      Process.detach(pid)
      {:pid => pid, :exitstatus => 0}

    rescue Errno::ENOENT, Errno::EACCES => ex
      {:error => ex}
    end

    # Execute cmd with blocking, return status (be careful: inside actor blocks it mailbox, use with defer)
    # options
    #   :working_dir
    #   :environment
    #   :stdin, :stdout, :stderr
    def execute(cmd, cfg = {})
      opts = spawn_options(cfg)
      pid  = Process::spawn(prepare_env(cfg), *Shellwords.shellwords(cmd), opts)

      timeout = cfg[:timeout] || 1.second
      status = 0

      Timeout.timeout(timeout) do
        _, st = Process.waitpid2(pid)
        status = st.exitstatus || st.termsig
      end

      {:pid => pid, :exitstatus => status}

    rescue Timeout::Error => ex
      if pid
        warn "[#{cfg[:name]}] send signal 9 to #{pid} (because of timeouted<#{timeout}> execution)"
        send_signal(pid, 9)
      end
      {:error => ex}

    rescue Errno::ENOENT, Errno::EACCES => ex
      {:error => ex}

    ensure
      Process.detach(pid) if pid
    end

    # get table
    # {pid => {:rss =>, :cpu =>, :ppid => , :start_time => }}
    # slow
    def ps_aux
      str = Process.send('`', PS_AUX_CMD).force_encoding('binary')
      h = {}
      str.each_line do |line|
        chunk = line.strip.split(/\s+/)
        h[chunk[0].to_i] = { :ppid => chunk[1].to_i, :cpu => chunk[2].to_i,
          :rss => chunk[3].to_i, :start_time => chunk[4] }
      end
      h
    end

    # normalize file
    def normalized_file(file, working_dir = nil)
      Pathname.new(file).expand_path(working_dir).to_s
    end

    def host
      @host ||= begin
        require 'socket'
        Socket.gethostname
      end
    end

    # set host for tests
    def host=(hostname)
      @host = hostname
    end

  private

    PS_AUX_CMD = if RUBY_PLATFORM.include?('darwin')
      'ps axo pid,ppid,pcpu,rss,start'
    else
      'ps axo pid,ppid,pcpu,rss,start_time'
    end

    def spawn_options(config = {})
      o = {pgroup: true, chdir: config[:working_dir] || '/'}
      o.update(out: [config[:stdout], 'a']) if config[:stdout]
      o.update(err: [config[:stderr], 'a']) if config[:stderr]
      o.update(in: config[:stdin]) if config[:stdin]

      if Eye::Settings.root?
        o.update(uid: Etc.getpwnam(config[:uid]).uid) if config[:uid]
        o.update(gid: Etc.getpwnam(config[:gid]).gid) if config[:gid]
      end

      o.update(umask: config[:umask]) if config[:umask]

      o
    end

    def prepare_env(config = {})
      env = {}

      (config[:environment] || {}).each do |k,v|
        env[k.to_s] = v && v.to_s
      end

      env
    end
  end

end