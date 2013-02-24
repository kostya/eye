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
    end

    true
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
    Eye::System.pid_alive?(self.pid) if self.pid
  end

  def send_signal(code)
    debug "send signal #{code}"

    res = Eye::System.send_signal(self.pid, code)
    error(res[:message]) if res[:status] != :ok

    res[:status] == :ok
  end

  # non blocking actor timeout
  def wait_for_condition(timeout, step = 0.1, &block)
    defer{ wait_for_condition_sync(timeout, step, &block) }
  end

  def execute(cmd, cfg = {})
    defer{ Eye::System::execute cmd, cfg }
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