gem 'posix-spawn'
require 'posix/spawn'

require "shellwords"
require 'pathname'

module Eye::System
  class << self

    # Check that pid realy exits
    # very fast
    def pid_alive?(pid)
      pid ? ::Process.kill(0, pid) && true : false
    rescue Errno::ESRCH
      false
    end

    # Send signal to process (uses for kill)
    # code: TERM(15), KILL(9), QUIT(3), ...
    def send_signal(pid, code = "TERM")
      code = code.to_s.upcase if code.is_a?(String) || code.is_a?(Symbol)

      ::Process.kill(code, pid)
      {:status => :ok}

    rescue Errno::ESRCH    
      {:status => :error, :message => "process not found"}

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
      Dir.chdir(cfg[:working_dir]) if cfg[:working_dir]
      opts = spawn_options(cfg)
      pid  = POSIX::Spawn::spawn(cfg[:environment] || {}, *Shellwords.shellwords(cmd), opts)
      ::Process.detach(pid)
      pid      
    end

    # Blocking execute cmd, return status
    # options
    #   :working_dir
    #   :environment
    #   :stdin, :stdout, :stderr
    def execute(cmd, cfg = {})
      Dir.chdir(cfg[:working_dir]) if cfg[:working_dir]
      opts = spawn_options(cfg)
      pid  = POSIX::Spawn::spawn(cfg[:environment] || {}, *Shellwords.shellwords(cmd), opts)

      timeout = cfg[:timeout] || 1.second
      Timeout.timeout(timeout) do
        Process.waitpid(pid)
      end

    rescue Timeout::Error
      send_signal(pid) if pid        
      :timeout
    end

    # get table
    # {pid => {:rss =>, :cpu =>, :ppid => , :cmd => }}
    # slow
    def ps_aux
      str = POSIX::Spawn.send('`', "ps axo pid,ppid,pcpu,rss,command")
      str.force_encoding('binary')
      lines = str.split("\n")      
      lines.shift # remove first line
      lines.inject(Hash.new) do |mem, line|
        chunk = line.strip.split(/\s+/).map(&:strip)
        mem[chunk[0].to_i] = {:rss => chunk[3].to_i, 
          :cpu => chunk[2].to_i, 
          :ppid => chunk[1].to_i, 
          :cmd => chunk[4..-1].join(' ')}
        mem
      end
    end

    # normalize file
    def normalized_file(file, working_dir = nil)
      Pathname.new(file).expand_path(working_dir).to_s
    end

  private

    def spawn_options(config = {})
      o = {}
      o = {chdir: config[:working_dir]} if config[:working_dir]
      o.update(out: [config[:stdout], "a"]) if config[:stdout]
      o.update(err: [config[:stderr], "a"]) if config[:stderr]
      o.update(in: config[:stdin]) if config[:stdin]
      o
    end
  end

end