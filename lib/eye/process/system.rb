require 'timeout'

module Eye::Process::System

  def load_pid_from_file    
    if File.exists?(self[:pid_file_ex])
      _pid = File.read(self[:pid_file_ex]).to_i 
      _pid > 0 ? _pid : nil
    end
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
    File.unlink(self[:pid_file_ex])
    true
  rescue 
    nil
  end

  def pid_file_ctime
    File.ctime(self[:pid_file_ex]) rescue Time.now
  end

  def process_realy_running?
    if self.pid
      res = Eye::System.check_pid_alive(self.pid)
      if res[:error] && res[:error].class != Errno::ESRCH
        error "process_realy_running?: check_pid_alive returns '#{res[:error].message}'" 
      end
      res[:result]
    else
      debug "process_realy_running?: called without pid"
      nil
    end
  end

  def send_signal(code)
    res = Eye::System.send_signal(self.pid, code)

    msg = "send_signal #{code} to #{self.pid}"
    msg += ", error<#{res[:error]}>" if res[:error]
    info msg

    res[:result] == :ok
  end

  # non blocking actor timeout
  def wait_for_condition(timeout, step = 0.1, &block)
    defer{ wait_for_condition_sync(timeout, step, &block) }
  end

  def execute(cmd, cfg = {})
    defer{ Eye::System::execute cmd, cfg }
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
    error "failsafe_save_pid: #{ex.message}"
    false
  end

private

  def wait_for_condition_sync(timeout, step, &block)
    res = nil

    Timeout::timeout(timeout.to_f) do
      sleep step.to_f until res = yield
    end

    res
  rescue Timeout::Error
    false
  end

end