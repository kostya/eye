require 'shellwords'
require 'pathname'

module Eye::System
  class << self

    # Check that pid realy exits
    # very fast
    def pid_alive?(pid)
      pid ? ::Process.kill(0, pid) && true : false
    rescue Errno::ESRCH, Errno::EPERM
      false
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

      ::Process.kill(code, pid) if pid
      {:status => :ok}

    rescue Errno::ESRCH    
      {:status => :error, :message => 'process not found'}

    rescue Errno::EPERM
      {:status => :error, :message => 'wrong permissions to kill'}

    rescue => e
      {:status => :error, :message => "failed signal #{code}: #{e.message}"}
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
      {:pid => pid}
      
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

      Timeout.timeout(cfg[:timeout] || 1.second) do
        Process.waitpid(pid)
      end

      {:pid => pid}

    rescue Timeout::Error => ex      
      send_signal(pid, 9) if pid
      {:error => ex}

    rescue Errno::ENOENT, Errno::EACCES => ex
      {:error => ex}

    ensure 
      Process.detach(pid) if pid
    end

    # get table
    # {pid => {:rss =>, :cpu =>, :ppid => , :cmd => , :start_time}}
    # slow
    def ps_aux
      cmd = if RUBY_PLATFORM.include?('darwin')
        'ps axo pid,ppid,pcpu,rss,start,command'
      else
        'ps axo pid,ppid,pcpu,rss,start_time,command'
      end

      str = Process.send('`', cmd).force_encoding('binary')
      lines = str.split("\n")
      lines.shift # remove first line
      lines.inject(Hash.new) do |mem, line|
        chunk = line.strip.split(/\s+/).map(&:strip)
        mem[chunk[0].to_i] = {
          :rss => chunk[3].to_i, 
          :cpu => chunk[2].to_i, 
          :ppid => chunk[1].to_i, 
          :start_time => chunk[4],
          :cmd => chunk[5..-1].join(' ')
        }
        mem
      end
    end

    # normalize file
    def normalized_file(file, working_dir = nil)
      Pathname.new(file).expand_path(working_dir).to_s
    end

    def host
      @host ||= `hostname`.chomp
    end

    # set host for tests
    def host=(hostname)
      @host = hostname
    end

  private

    def spawn_options(config = {})
      o = {}
      o = {chdir: config[:working_dir]} if config[:working_dir]
      o.update(out: [config[:stdout], 'a']) if config[:stdout]
      o.update(err: [config[:stderr], 'a']) if config[:stderr]
      o.update(in: config[:stdin]) if config[:stdin]
      o
    end

    def prepare_env(config = {})
      env = {}

      (config[:environment] || {}).each do |k,v|
        env[k.to_s] = v.to_s if v
      end

      # set PWD for unicorn respawn
      env['PWD'] = config[:working_dir] if config[:working_dir]

      env
    end
  end

end