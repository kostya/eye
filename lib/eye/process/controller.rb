module Eye::Process::Controller

  def send_command(command, *args)
    schedule command, *args, Eye::Reason::User.new(command)
  end

  def start
    res = if set_pid_from_file
      if process_really_running?
        info "process <#{self.pid}> from pid_file is already running"
        switch :already_running
        :ok
      else
        info "pid_file found, but process <#{self.pid}> is down, starting..."
        start_process
      end
    else
      info 'pid_file not found, starting...'
      start_process
    end

    res
  end

  def stop
    stop_process
    switch :unmonitoring
  end

  def restart
    unless pid # unmonitored case
      try_update_pid_from_file
    end

    restart_process
  end

  def monitor
    if self[:auto_start]
      start
    else
      if try_update_pid_from_file
        info "process <#{self.pid}> from pid_file is already running"
        switch :already_running
      else
        warn 'process not found, unmonitoring'
        schedule :unmonitor, Eye::Reason.new(:'not found')
      end
    end
  end

  def unmonitor
    switch :unmonitoring
  end

  def delete
    if self[:stop_on_delete]
      info 'process has stop_on_delete option, so sync-stop it first'
      stop
    end

    remove_watchers
    remove_children
    remove_triggers

    terminate
  end

  def signal(sig = 0)
    send_signal(sig) if self.pid
  end

  def user_command(name)
    if self[:user_commands] && c = self[:user_commands][name.to_sym]
      execute_user_command(name, c)
    end
  end

end
