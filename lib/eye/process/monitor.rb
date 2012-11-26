module Eye::Process::Monitor

private

  def check_alive_with_refresh_pid_if_needed
    if process_realy_running?
      return true

    else
      warn "process not realy running"

      # if pid file was rewrited
      newpid = load_pid_from_file
      if newpid != self.pid
        info "Process change pid, updating..."
        self.pid = newpid
        if process_realy_running?
          return true
        else
          warn "process not found"
          return false          
        end
      else
        warn "process not found"
        return false
      end
    end
  end
  
  def check_alive
    if state_name == :up

      # check that process runned
      unless process_realy_running?
        info "process not found, so :crushed"
        transit :crushed
      else
        # check that pid file exists
        ppid = load_pid_from_file
        if ppid != self.pid
          warn "process changed pid by itself (#{self.pid}) => (#{ppid})"
          save_pid_to_file
        end
      end
    end
  end

  def check_crush
    if state_name == :down

      if self[:keep_alive] && !@flapping
        info "process in down, so :start"
        queue :start
      else
        info "process in down, and something wrong, so :unmonitor"
        queue :unmonitor
      end
    end
  end

end