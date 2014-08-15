require 'shellwords'
require 'etc'
require 'timeout'

module Eye::System
  class << self
    # Check that pid really exits
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

    # Check that pid really exits
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
      pid = ::Process::spawn(prepare_env(cfg), *Shellwords.shellwords(cmd), spawn_options(cfg))

      {:pid => pid, :exitstatus => 0}

    rescue Errno::ENOENT, Errno::EACCES => ex
      {:error => ex}

    ensure
      Process.detach(pid) if pid
    end

    # Execute cmd with blocking, return status (be careful: inside actor blocks it mailbox, use with defer)
    # options
    #   :working_dir
    #   :environment
    #   :stdin, :stdout, :stderr
    def execute(cmd, cfg = {})
      pid = ::Process::spawn(prepare_env(cfg), *Shellwords.shellwords(cmd), spawn_options(cfg))

      timeout = cfg[:timeout] || 1.second
      status = 0

      Timeout.timeout(timeout) do
        _, st = Process.waitpid2(pid)
        status = st.exitstatus || st.termsig
      end

      {:pid => pid, :exitstatus => status}

    rescue Timeout::Error => ex
      if pid
        warn "[#{cfg[:name]}] sending :KILL signal to <#{pid}> due to timeout (#{timeout}s)"
        send_signal(pid, 9)
      end
      {:error => ex}

    rescue Errno::ENOENT, Errno::EACCES => ex
      {:error => ex}

    ensure
      Process.detach(pid) if pid
    end

    # normalize file
    def normalized_file(file, working_dir = nil)
      File.expand_path(file, working_dir)
    end

    def spawn_options(config = {})
      options = {
        pgroup: true,
        chdir: config[:working_dir] || '/'
      }

      options[:out]   = [config[:stdout], 'a'] if config[:stdout]
      options[:err]   = [config[:stderr], 'a'] if config[:stderr]
      options[:in]    = config[:stdin] if config[:stdin]
      options[:umask] = config[:umask] if config[:umask]
      options[:close_others] = false if config[:preserve_fds]
      options[:unsetenv_others] = true if config[:clear_env]

      if Eye::Local.root?
        options[:uid] = Etc.getpwnam(config[:uid]).uid if config[:uid]
        options[:gid] = Etc.getgrnam(config[:gid]).gid if config[:gid]
      end

      options
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
