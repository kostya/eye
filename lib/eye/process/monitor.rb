module Eye::Process::Monitor

private

  def load_external_pid_file
    newpid = failsafe_load_pid

    if !newpid
      self.pid = nil
      info 'load_external_pid_file: pid_file not found'
      :no_pid_file
    elsif process_pid_running?(newpid)
      self.pid = newpid
      res = compare_identity
      if res == :fail
        warn "load_external_pid_file: process <#{self.pid}> from pid_file failed check_identity"
        :bad_identity
      else
        args = Eye::SystemResources.args(self.pid)
        info "load_external_pid_file: process <#{self.pid}> from pid_file found and running (identity: #{res}) (#{args})"
        :ok
      end
    else
      @last_loaded_pid = newpid
      self.pid = nil
      info "load_external_pid_file: pid_file found, but process <#{newpid}> not found"
      :not_running
    end
  end

  def check_alive
    return unless up?

    # check that process runned
    if process_really_running?
      check_pid_file
    else
      warn "check_alive: process <#{self.pid}> not found"
      notify :info, 'crashed!'
      clear_pid_file(true) if control_pid?

      switch :crashed, reason: :crashed
    end
  end

  def check_pid_file
    ppid = failsafe_load_pid
    return if ppid == self.pid

    msg = "check_alive: pid_file (#{self[:pid_file]}) changed by itself (<#{self.pid}> => <#{ppid}>)"
    if control_pid?
      msg += ", reverting to <#{self.pid}> (the pid_file is controlled by eye)"
      unless failsafe_save_pid
        msg += ', pid_file write failed! O_o'
      end
    else
      changed_ago_s = Time.now - pid_file_ctime

      if !ppid
        msg += ", reverting to <#{self.pid}> (the pid_file is empty)"
        unless failsafe_save_pid
          msg += ', pid_file write failed! O_o'
        end

      elsif (changed_ago_s > self[:auto_update_pidfile_grace]) && process_pid_running?(ppid) && (compare_identity(ppid) != :fail)
        msg += ", trusting this change, and now monitor <#{ppid}>"
        self.pid = ppid

      elsif changed_ago_s > self[:revert_fuckup_pidfile_grace]
        msg += " over #{self[:revert_fuckup_pidfile_grace]}s ago, reverting to <#{self.pid}>, because <#{ppid}> not alive"
        unless failsafe_save_pid
          msg += ', pid_file write failed! O_o'
        end

      else
        msg += ', ignoring self-managed pid change'
      end
    end

    warn msg
  end

  def check_identity
    if compare_identity == :fail
      notify :info, 'crashed by identity!'
      switch :crashed, reason: :crashed_by_identity
      clear_pid_file if self[:clear_pid]
      false
    else
      true
    end
  end

  def check_crash
    unless down?
      debug { 'check crashed: skipped, process is not in down' }
      return
    end

    if self[:keep_alive]
      warn 'check crashed: process is down'

      if self[:restore_in]
        schedule in: self[:restore_in].to_f, command: :restore, reason: :crashed
      else
        schedule command: :restore, reason: :crashed
      end
    else
      warn 'check crashed: process without keep_alive'
      schedule command: :unmonitor, reason: :crashed
    end
  end

  def restore
    start if down?
  end

end
