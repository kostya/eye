require 'fileutils'

module Eye::Local
  class << self
    def dir
      @dir ||= begin
        if root?
        '/var/run/eye'
        else
          File.expand_path(File.join(home, '.eye'))
        end
      end
    end

    def dir=(d)
      @dir = d
    end

    def eyeconfig
      if root?
        '/etc/eye.conf'
      else
        File.expand_path(File.join(home, '.eyeconfig'))
      end
    end

    def root?
      Process::UID.eid == 0
    end

    def home
      h = ENV['EYE_HOME'] || ENV['HOME']
      raise "HOME undefined, should be HOME or EYE_HOME environment" unless h
      h
    end

    def path(path)
      File.join(dir, path)
    end

    def ensure_eye_dir
      FileUtils.mkdir_p( dir )
    end

    def socket_path
      path(ENV['EYE_SOCK'] || "sock#{ENV['EYE_V']}")
    end

    def pid_path
      path(ENV['EYE_PID'] || "pid#{ENV['EYE_V']}")
    end

    def cache_path
      path("processes#{ENV['EYE_V']}.cache")
    end

    def client_timeout
      5
    end

    def supported_setsid?
      RUBY_VERSION >= '2.0'
    end

    def host
      @host ||= begin
        require 'socket'
        Socket.gethostname
      end
    end

    def host=(hostname)
      @host = hostname
    end

    def eyefile
      @eyefile ||= begin
        path = File.expand_path("Eyefile")
        File.exist?(path) ? path : nil
      end
    end

    attr_accessor :local_runner
  end
end
