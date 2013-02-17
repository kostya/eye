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
        warn 'check_alive: process not found'
        notify :warn, 'crushed!'
        switch :crushed
      else
        # check that pid_file still here
        ppid = failsafe_load_pid
        
        if ppid != self.pid
          msg = "check_alive: pid_file(#{self[:pid_file]}) changes by itself (#{self.pid}) => (#{ppid})"
          if control_pid?
            msg += ", not correct, pid_file is under eye control, so rewrited back #{self.pid}"
            save_pid_to_file rescue msg += ', (Can`t rewrite pid_file O_o)'
          else
            if ppid == nil
              msg += ', rewrited because empty'
              save_pid_to_file rescue msg += ', (Can`t rewrite pid_file O_o)'
            elsif (Time.now - pid_file_ctime > REWRITE_FACKUP_PIDFILE_PERIOD)
              msg += ", > #{REWRITE_FACKUP_PIDFILE_PERIOD.inspect} ago, so rewrited (even if pid_file not under eye control)"
              save_pid_to_file rescue msg += ', (Can`t rewrite pid_file O_o)'
            else
              msg += ', not under eye control, so ignored'
            end
          end

          warn msg
        end
      end
    end
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

  def check_crush
    if down?
      if self[:keep_alive] && !@flapping
        warn 'check crushed: process is down'
        schedule :start, 'crushed'
      else
        warn 'check crushed: process is down, and flapping happens (or not keep_alive option)'
        schedule :unmonitor, 'flapping'
      end
    end
  end

  public :check_crush # bug of celluloid 0.12

end
