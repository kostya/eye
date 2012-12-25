module Eye::Process::Controller

  # All controller methods should call with queue
  #   queue :start
  #   queue :stop

  def queue(command, reason = "")
    info "queue: #{command} #{reason}"
    @queue.add_no_dup(command)
  end

  def send_command(command)
    if command == :remove
      remove       
    else
      self.queue(command)
    end
  end

  def start
    info "=> start"

    if set_pid_from_file
      if process_realy_running?
        info "process found (#{self.pid}) and already running"
        transit :already_running
        :ok
      else
        info "pid_file found, but process in pid_file(#{self.pid}) not found, starting..."
        start_process
      end
    else
      info "pid_file not found, so starting process..."
      start_process
    end
  end

  def stop
    info "=> stop"
    stop_process
    transit :unmonitoring
  end

  def restart
    info "=> restart"
    restart_process
  end

  def monitor
    info "=> monitor"
    if self[:auto_start]
      start
    else
      info "not supported, yet!"
    end
  end

  def unmonitor
    info "=> unmonitor"
    transit :unmonitoring
  end
  
  def remove
    remove_watchers
    remove_childs
    remove_triggers

    # actors just die, without stopping process
    @queue.terminate
    self.terminate
  end
  
end