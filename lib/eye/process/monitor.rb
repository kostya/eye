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
        info "process changed pid to #{newpid}, updating..."
        self.pid = newpid

        if process_realy_running?
          return true
        else
          warn "process with new_pid #{newpid} not found"
          return false          
        end
      else
        debug "process not found"
        return false
      end
    end
  end

  REWRITE_FACKUP_PIDFILE_PERIOD = 2.minutes
  
  def check_alive
    if state_name == :up

      # check that process runned
      unless process_realy_running?
        warn "check_alive: process not found, so :crushed"
        notify :warn, "crushed!"
        switch :crushed
      else
        # check that pid_file still here
        ppid = load_pid_from_file
        if ppid != self.pid
          msg = "check_alive: pid_file(#{self[:pid_file]}) changes by itself (#{self.pid}) => (#{ppid})"
          if control_pid?
            msg += ", not correct, pid_file is under eye control, so rewrited back #{self.pid}"
            save_pid_to_file
          else
            if ppid == nil
              msg += ", rewrited because empty"
              save_pid_to_file
            elsif (Time.now - pid_file_ctime > REWRITE_FACKUP_PIDFILE_PERIOD)
              msg += ", > #{REWRITE_FACKUP_PIDFILE_PERIOD.inspect} ago, so rewrited (even if pid_file not under eye control)"
              save_pid_to_file
            else
              msg += ", not under eye control, so ignored"
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
        warn "check crushed: process is down, so :start"
        queue :start
      else
        warn "check crushed: process is down, and flapping happens, so :unmonitor"
        queue :unmonitor
      end
    end
  end

end
