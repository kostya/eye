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

  REWRITE_FACKUP_PIDFILE_PERIOD = 2.minutes
  
  def check_alive
    if state_name == :up

      # check that process runned
      unless process_realy_running?
        info "process not found, so :crushed"
        transit :crushed
      else
        # check that pid_file still here
        ppid = load_pid_from_file
        if ppid != self.pid
          msg = "process changed pid by itself (#{self.pid}) => (#{ppid})"
          if control_pid?
            msg += ", not correct, pid_file is under eye control, so rewrited"
            save_pid_to_file
          else
            if ppid == nil
              msg += ", rewrited"
              save_pid_to_file
            elsif (Time.now - pid_file_ctime > REWRITE_FACKUP_PIDFILE_PERIOD)
              msg += ", was so old, so rewrited (even if pid_file not under control, because it too old)"
              save_pid_to_file
            else
              msg += ", not under control, ignored"
            end
          end

          warn msg
        end
      end
    end
  end

  def check_crush
    if state_name == :down

      if self[:keep_alive] && !@flapping
        info "check_crush: process in down, so :start"
        queue :start
      else
        info "check_crush: process in down, and something wrong, so :unmonitor"
        queue :unmonitor
      end
    end
  end

end