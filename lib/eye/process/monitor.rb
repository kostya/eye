module Eye::Process::Monitor

private

  def check_alive_with_refresh_pid_if_needed
    if process_really_running?
      return true

    else
      warn 'process not really running'
      try_update_pid_from_file
    end
  end

  def try_update_pid_from_file
    # if pid file was rewritten
    newpid = load_pid_from_file
    if newpid != self.pid
      info "process <#{self.pid}> changed pid to <#{newpid}>, updating..." if self.pid
      self.pid = newpid

      if process_really_running?
        return true
      else
        warn "process <#{newpid}> was not found"
        return false
      end
    else
      debug 'process was not found'
      return false
    end
  end

  REWRITE_FACKUP_PIDFILE_PERIOD = 2.minutes

  def check_alive
    if up?

      # check that process runned
      unless process_really_running?
        warn "check_alive: process <#{self.pid}> not found"
        notify :info, 'crashed!'
        clear_pid_file if control_pid? && self.pid && load_pid_from_file == self.pid

        switch :crashed, Eye::Reason.new(:crashed)
      else
        # check that pid_file still here
        ppid = failsafe_load_pid

        if ppid != self.pid
          msg = "check_alive: pid_file (#{self[:pid_file]}) changed by itself (<#{self.pid}> => <#{ppid}>)"
          if control_pid?
            msg += ", reverting to <#{self.pid}> (the pid_file is controlled by eye)"
            unless failsafe_save_pid
              msg += ", pid_file write failed!"
            end
          else
            if ppid == nil
              msg += ", reverting to <#{self.pid}> (the pid_file is empty)"
              unless failsafe_save_pid
                msg += ", pid_file write failed!"
              end
            elsif (Time.now - pid_file_ctime > REWRITE_FACKUP_PIDFILE_PERIOD)
              msg += " over #{REWRITE_FACKUP_PIDFILE_PERIOD}s ago, reverting to <#{self.pid}>"
              unless failsafe_save_pid
                msg += ", pid_file write failed!"
              end
            else
              msg += ', ignoring self-managed pid change'
            end
          end

          warn msg
        end
      end
    end
  end

  def check_crash
    if down?
      if self[:keep_alive]
        warn 'check crashed: process is down'

        if self[:restore_in]
          schedule_in self[:restore_in].to_f, :restore, Eye::Reason.new(:crashed)
        else
          schedule :restore, Eye::Reason.new(:crashed)
        end
      else
        warn 'check crashed: process without keep_alive'
        schedule :unmonitor, Eye::Reason.new(:crashed)
      end
    else
      debug 'check crashed: skipped, process is not in down'
    end
  end

  def restore
    start if down?
  end

end
