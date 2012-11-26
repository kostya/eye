module Eye::Process::Commands

  REASON_ADVICE = {
    :timeout => "increase start_timeout interval",
    :pid_not_found => "pid_file does not appear, check command",
    :not_realy_running => "process not found",
    :cant_write_pid => "pid_file is not writable for eye"
  }

  def start_process
    info "start_process command"

    unless self[:start_command]
      info "no start command, skip"
      return :no_start_command
    end

    transit :starting

    info "execute command: #{self[:start_command]}"

    result = if self[:daemonize]
      spawn_process
    else
      execute_process
    end

    if result == :ok      
      info "process (#{self.pid}) ok started"
      transit :started
    else
      warn "process (#{self.pid}) cant start, reason: #{result}! #{REASON_ADVICE[result]}"
      
      if self.pid && Eye::System.pid_alive?(self.pid)
        info "try kill, what remains from process (#{self.pid}), because its failed to start"
        send_signal(:TERM)
        sleep 0.2        
      end
      self.pid = nil

      transit :crushed, result
    end

    result

  rescue StateMachine::InvalidTransition => e
    warn "state transition error '#{e.message}'"

    :state_error
  end
  
  def stop_process
    info "stop_process command"

    transit :stopping

    kill_process

    if process_realy_running?
      warn "process not stopped, check command/signals, or sets stop_timeout manually, seems its realy soft, now return to :up"
      transit :cant_kill
      nil

    else
      transit :stopped

      clear_pid_file if self[:clear_pid_file]
      
      true

    end

  rescue StateMachine::InvalidTransition => e
    warn "state transition error '#{e.message}'"
    nil
  end

 
  def restart_process
    info "restart_process command"

    transit :restarting

    if self[:restart_command]
      cmd = prepare_command(self[:restart_command])
      Eye::System.execute(cmd, config.merge(:timeout => self[:restart_timeout]))

      sleep self[:restart_grace].to_f

      result = check_alive_with_refresh_pid_if_needed
      transit(result ? :restarted : :crushed)
    else
      stop_process
      start_process
    end

    true

  rescue StateMachine::InvalidTransition => e
    warn "state transition error '#{e.message}'"
    nil
  end

private

  def kill_process
    if self[:stop_command]      
      cmd = prepare_command(self[:stop_command])
      res = Eye::System.execute(cmd, config.merge(:timeout => self[:stop_timeout]))
      info "execute command: #{self[:stop_command]} with #{res.inspect}"

    elsif self[:stop_signals]
      info "execute command: #{self[:stop_signals].inspect}"
      stop_signals = self[:stop_signals].clone

      signal = stop_signals.shift
      send_signal(signal)

      while stop_signals.present?
        delay = stop_signals.shift
        signal = stop_signals.shift

        sleep(delay.to_f)
        unless process_realy_running?
          info "has terminated"
          break
        end

        send_signal(signal)
      end
    else
      info "execute command: kill -TERM {{PID}}"
      send_signal(:TERM)
    end

    sleep self[:stop_grace].to_f
  end
  
  def prepare_command(command)
    command.to_s.gsub("{{PID}}", self.pid.to_s)
  end

  def spawn_process
    self.pid = Eye::System.daemonize(self[:start_command], config)
    sleep self[:start_grace].to_f
    if process_realy_running?
      s = save_pid_to_file rescue nil
      s ? :ok : :cant_write_pid
    else
      :not_realy_running
    end
  end

  def execute_process
    res = Eye::System.execute(self[:start_command], config.merge(:timeout => config[:start_timeout]))

    return :timeout if res == :timeout

    sleep self[:start_grace].to_f

    return :pid_not_found unless set_pid_from_file
    return :not_realy_running unless process_realy_running?

    return :ok
  end

end