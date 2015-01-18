module Eye::Process::Commands

  def start_process
    debug { 'start_process command' }

    switch :starting

    unless self[:start_command]
      warn 'no :start_command found, unmonitoring'
      switch :unmonitoring, Eye::Reason.new(:no_start_command)
      return :no_start_command
    end

    result = self[:daemonize] ? daemonize_process : execute_process

    if !result[:error]
      debug { "process <#{self.pid}> started successfully" }
      switch :started
    else
      error "process <#{self.pid}> failed to start (#{result[:error].inspect})"

      if process_really_running?
        warn "killing <#{self.pid}> due to error"
        send_signal(:KILL)
        sleep 0.2 # little grace
      end

      self.pid = nil
      switch :crashed
    end

    result

  rescue StateMachine::InvalidTransition, Eye::Process::StateError => e
    warn "wrong switch '#{e.message}'"

    :state_error
  end

  def stop_process
    debug { 'stop_process command' }

    switch :stopping

    kill_process

    if process_really_running?
      warn "process <#{self.pid}> was not stopped; try checking your command/signals or tuning the stop_timeout/stop_grace values"

      switch :unmonitoring, Eye::Reason.new(:'not stopped (soft command)')
      nil

    else
      switch :stopped

      clear_pid_file if self[:clear_pid] # by default for all

      true
    end

  rescue StateMachine::InvalidTransition, Eye::Process::StateError => e
    warn "wrong switch '#{e.message}'"
    nil
  end

  def restart_process
    debug { 'restart_process command' }

    switch :restarting

    if self[:restart_command]
      execute_restart_command
      sleep_grace(:restart_grace)
      result = check_alive_with_refresh_pid_if_needed
      switch(result ? :restarted : :crashed)
    else
      stop_process
      start_process
    end

    true

  rescue StateMachine::InvalidTransition, Eye::Process::StateError => e
    warn "wrong switch '#{e.message}'"
    nil
  end

private

  def kill_process
    unless self.pid
      error 'cannot stop a process without a pid'
      return
    end

    if self[:stop_command]
      cmd = prepare_command(self[:stop_command])
      info "executing: `#{cmd}` with stop_timeout: #{self[:stop_timeout].to_f}s and stop_grace: #{self[:stop_grace].to_f}s"
      res = execute(cmd, config.merge(:timeout => self[:stop_timeout]))

      if res[:error]

        if res[:error].class == Timeout::Error
          error "stop_command failed with #{res[:error].inspect}; try tuning the stop_timeout value"
        else
          error "stop_command failed with #{res[:error].inspect}"
        end
      end

      sleep_grace(:stop_grace)

    elsif self[:stop_signals]
      info "executing stop_signals #{self[:stop_signals].inspect}"
      stop_signals = self[:stop_signals].clone

      signal = stop_signals.shift
      send_signal(signal)

      while stop_signals.present?
        delay = stop_signals.shift
        signal = stop_signals.shift

        if wait_for_condition(delay.to_f, 0.3){ !process_really_running? }
          info 'has terminated'
          break
        end

        send_signal(signal) if signal
      end

      sleep_grace(:stop_grace)

    else # default command
      debug { "executing: `kill -TERM #{self.pid}` with stop_grace: #{self[:stop_grace].to_f}s" }
      send_signal(:TERM)

      sleep_grace(:stop_grace)

      # if process not die here, by default we force kill it
      if process_really_running?
        warn "process <#{self.pid}> did not die after TERM, sending KILL"
        send_signal(:KILL)
        sleep 0.1 # little grace
      end
    end
  end

  def execute_restart_command
    unless self.pid
      error 'cannot restart a process without a pid'
      return
    end

    cmd = prepare_command(self[:restart_command])
    info "executing: `#{cmd}` with restart_timeout: #{self[:restart_timeout].to_f}s and restart_grace: #{self[:restart_grace].to_f}s"

    res = execute(cmd, config.merge(:timeout => self[:restart_timeout]))

    if res[:error]

      if res[:error].class == Timeout::Error
        error "restart_command failed with #{res[:error].inspect}; try tuning the restart_timeout value"
      else
        error "restart_command failed with #{res[:error].inspect}"
      end
    end

    res
  end

  def daemonize_process
    time_before = Time.now
    res = Eye::System.daemonize(self[:start_command], config)
    start_time = Time.now - time_before

    info "daemonizing: `#{self[:start_command]}` with start_grace: #{self[:start_grace].to_f}s, env: '#{environment_string}', <#{res[:pid]}> (in #{self[:working_dir]})"

    if res[:error]

      if res[:error].message == 'Permission denied - open'
        error "daemonize failed with #{res[:error].inspect}; make sure #{[self[:stdout], self[:stderr]]} are writable"
      else
        error "daemonize failed with #{res[:error].inspect}"
      end

      return {:error => res[:error].inspect}
    end

    self.pid = res[:pid]

    unless self.pid
      error 'no pid was returned'
      return {:error => :empty_pid}
    end

    sleep_grace(:start_grace)

    unless process_really_running?
      error "process <#{self.pid}> not found, it may have crashed (#{check_logs_str})"
      return {:error => :not_really_running}
    end

    # if we using leaf child stratedy, pid should be used as last child process
    if self[:use_leaf_child]
      if lpid = Eye::SystemResources.leaf_child(self.pid)
        info "leaf child for <#{self.pid}> found: <#{lpid}>, accepting it!"
        self.parent_pid = self.pid
        self.pid = lpid
      else
        warn "leaf child not found for <#{self.pid}>, skipping it"
      end
    end

    if control_pid? && !failsafe_save_pid
      return {:error => :cant_write_pid}
    end

    res
  end

  def execute_process
    info "executing: `#{self[:start_command]}` with start_timeout: #{config[:start_timeout].to_f}s, start_grace: #{self[:start_grace].to_f}s, env: '#{environment_string}' (in #{self[:working_dir]})"
    time_before = Time.now

    res = execute(self[:start_command], config.merge(:timeout => config[:start_timeout]))
    start_time = Time.now - time_before

    if res[:error]

      if res[:error].message == 'Permission denied - open'
        error "execution failed with #{res[:error].inspect}; ensure that #{[self[:stdout], self[:stderr]]} are writable"
      elsif res[:error].class == Timeout::Error
        error "execution failed with #{res[:error].inspect}; try increasing the start_timeout value (the current value of #{self[:start_timeout]}s seems too short)"
      else
        error "execution failed with #{res[:error].inspect}"
      end

      return {:error => res[:error].inspect}
    end

    sleep_grace(:start_grace)

    unless set_pid_from_file
      error "exit status #{res[:exitstatus]}, pid_file (#{self[:pid_file_ex]}) did not appear within the start_grace period (#{self[:start_grace].to_f}s); check your start_command, or tune the start_grace value (eye expect process to create pid_file in self-daemonization mode)"
      return {:error => :pid_not_found}
    end

    unless process_really_running?
      error "exit status #{res[:exitstatus]}, process <#{self.pid}> (from #{self[:pid_file_ex]}) was not found; ensure that the pid_file is being updated correctly (#{check_logs_str})"
      return {:error => :not_really_running}
    end

    res[:pid] = self.pid
    info "exit status #{res[:exitstatus]}, process <#{res[:pid]}> (from #{self[:pid_file_ex]}) was found"
    res
  end

  def check_logs_str
    if !self[:stdout] && !self[:stderr]
      'you may want to configure stdout/err/all logs for this process'
    else
      "you should check the process logs #{[self[:stdout], self[:stderr]]}"
    end
  end

  def prepare_command(command)
    if self.pid
      command.to_s.gsub('{{PID}}', self.pid.to_s).gsub('{PID}', self.pid.to_s)
    else
      command
    end
  end

  def sleep_grace(grace_name)
    grace = self[grace_name].to_f
    info "sleeping for :#{grace_name} #{grace}"
    sleep grace
  end

  def execute_user_command(name, cmd)
    info "executing user command #{name} #{cmd.inspect}"

    # cmd is string, or array of signals
    if cmd.is_a?(String)
      cmd = prepare_command(cmd)
      res = execute(cmd, config.merge(:timeout => 120))
      error "cmd #{cmd} error #{res.inspect}" if res[:error]
    elsif cmd.is_a?(Array)
      signals = cmd.clone
      signal = signals.shift
      send_signal(signal)

      while signals.present?
        delay = signals.shift
        signal = signals.shift
        if wait_for_condition(delay.to_f, 0.3){ !process_really_running? }
          info 'has terminated'
          break
        end
        send_signal(signal) if signal
      end
    else
      warn "unknown user command #{c}"
    end
  end

end
