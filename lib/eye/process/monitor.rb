module Eye::Process::Monitor

private

  def check_alive_with_refresh_pid_if_needed
    if process_realy_running?
      return true

    else
      warn 'process not realy running'
      try_update_pid_from_file
    end
  end

  def try_update_pid_from_file
    # if pid file was rewrited
    newpid = load_pid_from_file
    if newpid != self.pid 
      info "process changed pid to #{newpid}, updating..." if self.pid
      self.pid = newpid

      if process_realy_running?
        return true
      else
        warn "process with new_pid #{newpid} not found"
        return false          
      end
    else
      debug 'process not found'
      return false
    end
  end

  REWRITE_FACKUP_PIDFILE_PERIOD = 2.minutes
  
  def check_alive
    if up?

      # check that process runned
      unless process_realy_running?
        warn "check_alive: process(#{self.pid}) not found!"
        notify :warn, 'crashed!'
        switch :crashed
      else
        # check that pid_file still here
        ppid = failsafe_load_pid
        
        if ppid != self.pid
          msg = "check_alive: pid_file(#{self[:pid_file]}) changes by itself (pid:#{self.pid}) => (pid:#{ppid})"
          if control_pid?
            msg += ", not correct, pid_file is under eye control, so rewrited back pid:#{self.pid}"
            unless failsafe_save_pid
              msg += ', (Can`t rewrite pid_file O_o)'
            end
          else
            if ppid == nil
              msg += ', rewrited because empty'
              unless failsafe_save_pid
                msg += ', (Can`t rewrite pid_file O_o)'
              end
            elsif (Time.now - pid_file_ctime > REWRITE_FACKUP_PIDFILE_PERIOD)
              msg += ", > #{REWRITE_FACKUP_PIDFILE_PERIOD.inspect} ago, so rewrited (even if pid_file not under eye control)"
              unless failsafe_save_pid
                msg += ', (Can`t rewrite pid_file O_o)'
              end
            else
              msg += ', not under eye control, so ignored'
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
        schedule :start, 'crashed'
      else
        warn 'check crashed: process without keep_alive'
        schedule :unmonitor, 'crashed'
      end
    else
      debug 'check crashed: skipped, process is not in down'
    end
  end

  public :check_crash # bug of celluloid 0.12

end
