require 'fileutils'

module Eye::Settings
  module_function
  
  def dir
    if root?
      '/var/run/eye'
    else
      File.expand_path(File.join(home, '.eye'))
    end
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
    ENV['EYE_HOME'] || ENV['HOME']
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
  
  def client_timeout
    5
  end

  def supported_setsid?
    RUBY_VERSION >= '2.0'
  end

end