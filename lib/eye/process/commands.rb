module Eye::Process::Commands

  def start_process
    debug 'start_process command'

    switch :starting

    unless self[:start_command]
      warn 'no start command, so unmonitoring'
      switch :unmonitoring
      return :no_start_command
    end

    result = self[:daemonize] ? daemonize_process : execute_process

    if !result[:error]
      debug "process (#{self.pid}) ok started"
      switch :started
    else
      error "process (#{self.pid}) failed to start (#{result[:error].inspect})"
      if process_realy_running?
        warn "kill, what remains from process (#{self.pid}), because its failed to start (without pid_file impossible to monitoring)"
        send_signal(:KILL)
        sleep 0.2 # little grace
      end

      self.pid = nil
      switch :crashed
    end

    result

  rescue StateMachine::InvalidTransition => e
    warn "wrong switch '#{e.message}'"

    :state_error
  end
  
  def stop_process
    debug 'stop_process command'

    switch :stopping

    kill_process

    if process_realy_running?
      warn 'NOT STOPPED, check command/signals, or tune stop_timeout/stop_grace, seems it was really soft'

      switch :unmonitoring
      nil

    else
      switch :stopped

      if control_pid?
        info "delete pid_file: #{self[:pid_file_ex]}"
        clear_pid_file 
      end
      
      true

    end

  rescue StateMachine::InvalidTransition => e
    warn "wrong switch '#{e.message}'"
    nil
  end

  def restart_process
    debug 'restart_process command'

    switch :restarting

    if self[:restart_command]
      execute_restart_command
      sleep self[:restart_timeout].to_f
      result = check_alive_with_refresh_pid_if_needed
      switch(result ? :restarted : :crashed)
    else
      stop_process
      start_process
    end

    true

  rescue StateMachine::InvalidTransition => e
    warn "wrong switch '#{e.message}'"
    nil
  end

private

  def kill_process
    return unless self.pid

    if self[:stop_command]
      cmd = prepare_command(self[:stop_command])
      res = execute(cmd, config.merge(:timeout => self[:stop_timeout]))
      info "executing: `#{cmd}` with stop_timeout: #{self[:stop_timeout].to_f}s and stop_grace: #{self[:stop_grace].to_f}s"

      if res[:error]
        error "raised with #{res[:error].inspect}"

        if res[:error].class == Timeout::Error
          error 'you should tune stop_timeout setting'
        end
      end

      sleep self[:stop_grace].to_f

    elsif self[:stop_signals]
      info "executing stop_signals #{self[:stop_signals].inspect}"
      stop_signals = self[:stop_signals].clone

      signal = stop_signals.shift
      send_signal(signal)

      while stop_signals.present?
        delay = stop_signals.shift
        signal = stop_signals.shift

        if wait_for_condition(delay.to_f, 0.1){ !process_realy_running? }
          info 'has terminated'
          break
        end

        send_signal(signal)
      end

      sleep self[:stop_grace].to_f

    else # default command
      info "executing: `kill -TERM #{self.pid}` with stop_grace: #{self[:stop_grace].to_f}s"
      send_signal(:TERM)
      
      sleep self[:stop_grace].to_f

      # if process not die here, by default we force kill it
      if process_realy_running?
        warn "process not die after TERM and stop_grace #{self[:stop_grace].to_f}s, so send KILL"
        send_signal(:KILL)
        sleep 0.1 # little grace
      end
    end
  end

  def execute_restart_command
    cmd = prepare_command(self[:restart_command])
    info "executing: `#{cmd}` with restart_timeout: #{self[:restart_timeout].to_f}s and restart_grace: #{self[:restart_grace].to_f}s"

    res = execute(cmd, config.merge(:timeout => self[:restart_timeout]))

    if res[:error]
      error "restart raised with #{res[:error].inspect}"

      if res[:error].class == Timeout::Error
        error 'you should tune restart_timeout setting'
      end
    end

    res
  end
  
  def daemonize_process
    time_before = Time.now
    res = Eye::System.daemonize(self[:start_command], config)
    start_time = Time.now - time_before

    info "daemonizing: `#{self[:start_command]}` with start_grace: #{self[:start_grace].to_f}s, env: #{self[:environment].inspect}, working_dir: #{self[:working_dir]} (pid:#{res[:pid]})"

    if res[:error]
      error "raised with #{res[:error].inspect}"

      if res[:error].message == 'Permission denied - open'
        error 'seems stdout/err/all files is not writable'
      end

      return {:error => res[:error].inspect}
    end
    
    self.pid = res[:pid]

    unless self.pid
      error 'returned empty pid, WTF O_o'
      return {:error => :empty_pid}
    end

    sleep self[:start_grace].to_f

    unless process_realy_running?
      error "process with pid(#{self.pid}) not found, may be crashed (#{check_logs_str})"
      return {:error => :not_realy_running}
    end

    unless failsafe_save_pid
      return {:error => :cant_write_pid} 
    end
    
    res
  end

  def execute_process
    info "executing: `#{self[:start_command]}` with start_timeout: #{config[:start_timeout].to_f}s, start_grace: #{self[:start_grace].to_f}s, env: #{self[:environment].inspect}, working_dir: #{self[:working_dir]}"
    time_before = Time.now

    res = execute(self[:start_command], config.merge(:timeout => config[:start_timeout]))
    start_time = Time.now - time_before    

    if res[:error]
      error "raised with #{res[:error].inspect}"

      if res[:error].message == 'Permission denied - open'
        error 'seems stdout/err/all files is not writable'
      end

      if res[:error].class == Timeout::Error
        error "try to increase start_timeout interval (current #{self[:start_timeout]} seems too small, for process self-daemonization)"
      end

      return {:error => res[:error].inspect}
    end

    sleep self[:start_grace].to_f

    unless set_pid_from_file
      error "pid_file(#{self[:pid_file_ex]}) does not appears after start_grace #{self[:start_grace].to_f}, check start_command, or tune start_grace (eye dont know what to monitor without pid)"
      return {:error => :pid_not_found}
    end

    unless process_realy_running?
      error "process in pid_file(#{self[:pid_file_ex]})(#{self.pid}) not found, maybe process do not write there actual pid, or just crashed (#{check_logs_str})"
      return {:error => :not_realy_running}
    end

    res[:pid] = self.pid
    info "process get pid:#{res[:pid]}, pid_file #{self[:pid_file_ex]}"
    res
  end

  def check_logs_str
    if !self[:stdout] && !self[:stderr]
      'maybe should add stdout/err/all logs'
    else
      "check also it stdout/err/all logs #{[self[:stdout], self[:stderr]].inspect}"
    end    
  end

  def prepare_command(command)
    if self.pid
      command.to_s.gsub('{{PID}}', self.pid.to_s).gsub('{PID}', self.pid.to_s)
    else
      command
    end
  end

end
