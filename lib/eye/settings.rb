require 'fileutils'

module Eye::Settings

  module_function
  
  def dir
    File.expand_path(File.join(ENV["HOME"], '.eye'))
  end
  
  def path(path)
    File.join(dir, path)
  end

  def ensure_eye_dir
    FileUtils.mkdir_p( dir )
  end

  def socket_path
    path('sock')
  end
  
  def pid_path
    path('pid')
  end
  
  def client_timeout
    5 # secs
  end

end