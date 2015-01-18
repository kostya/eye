require 'timeout'

module Eye::Process::System

  def load_pid_from_file
    res = if File.exists?(self[:pid_file_ex])
      _pid = File.read(self[:pid_file_ex]).to_i
      _pid > 0 ? _pid : nil
    end

    res
  end

  def set_pid_from_file
    self.pid = load_pid_from_file
  end

  def save_pid_to_file
    if self.pid
      File.open(self[:pid_file_ex], 'w') do |f|
        f.write self.pid
      end
      true
    else
      false
    end
  end

  def clear_pid_file
    info "delete pid_file: #{self[:pid_file_ex]}"
    File.unlink(self[:pid_file_ex])
    true
  rescue
    nil
  end

  def pid_file_ctime
    File.ctime(self[:pid_file_ex]) rescue Time.now
  end

  def process_really_running?
    process_pid_running?(self.pid)
  end

  def process_pid_running?(pid)
    res = Eye::System.check_pid_alive(pid)
    debug { "process_really_running?: <#{pid}> #{res.inspect}" }
    !!res[:result]
  end

  def send_signal(code)
    res = Eye::System.send_signal(self.pid, code)

    msg = "send_signal #{code} to <#{self.pid}>"
    msg += ", error<#{res[:error]}>" if res[:error]
    info msg

    res[:result] == :ok
  end

  def wait_for_condition(timeout, step = 0.1, &block)
    res = nil
    sumtime = 0

    loop do
      tm = Time.now
      res = yield # note that yield can block actor here and timeout can be overhead
      return res if res
      sleep step.to_f
      sumtime += (Time.now - tm)
      return false if sumtime > timeout
    end
  end

  def execute(cmd, cfg = {})
    defer{ Eye::System::execute cmd, cfg }
  end

  def execute_sync(cmd, opts = {:timeout => 1.second})
    res = execute cmd, self.config.merge(opts)
    info "execute_sync `#{cmd}` with res: #{res}"
    res
  end

  def execute_async(cmd, opts = {})
    res = Eye::System.daemonize(cmd, self.config.merge(opts))
    info "execute_async `#{cmd}` with res: #{res}"
    res
  end

  def failsafe_load_pid
    pid = load_pid_from_file

    if !pid
      # this is can be symlink changed case
      sleep 0.1
      pid = load_pid_from_file
    end

    pid
  end

  def failsafe_save_pid
    save_pid_to_file
    true
  rescue => ex
    log_ex(ex)
    false
  end

  def expand_path(path)
    File.expand_path(path, self[:working_dir])
  end

end
