module Eye::Process::Controller

  # scheduled actions
  # :update_config, :start, :stop, :restart, :unmonitor, :monitor, :break_chain, :delete, :signal, :user_command

  def start
    if load_external_pid_file == :ok
      switch :already_running
      :ok
    else
      start_process
    end
  end

  def stop
    stop_process
    switch :unmonitoring
  end

  def restart
    load_external_pid_file unless pid # unmonitored case
    restart_process
  end

  def monitor
    if self[:auto_start]
      start
    elsif load_external_pid_file == :ok
      switch :already_running
    else
      schedule command: :unmonitor, reason: 'not found'
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
