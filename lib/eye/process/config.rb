module Eye::Process::Config

  DEFAULTS = {
    :keep_alive => true, # restart when crashed
    :check_alive_period => 5.seconds,

    :start_timeout => 15.seconds,
    :stop_timeout => 10.seconds,
    :restart_timeout => 10.seconds,

    :start_grace => 2.5.seconds,
    :stop_grace => 0.5.seconds,
    :restart_grace => 1.second,

    :daemonize => false,
    :auto_start => true, # auto start on monitor action

    :children_update_period => 30.seconds,
    :clear_pid => true, # by default clear pid on stop

    :auto_update_pidfile_grace => 30.seconds,
    :revert_fuckup_pidfile_grace => 120.seconds,
  }

  def prepare_config(new_config)
    h = DEFAULTS.merge(new_config)
    h[:pid_file_ex] = Eye::System.normalized_file(h[:pid_file], h[:working_dir]) if h[:pid_file]
    h[:checks] = {} if h[:checks].blank?
    h[:triggers] = {} if h[:triggers].blank?
    h[:children_update_period] = h[:monitor_children][:children_update_period] if h[:monitor_children] && h[:monitor_children][:children_update_period]

    # check speedy flapping by default
    if h[:triggers].blank? || !h[:triggers][:flapping]
      h[:triggers] ||= {}
      h[:triggers][:flapping] = {:type => :flapping, :times => 10, :within => 10.seconds}
    end

    h[:stdout] = Eye::System.normalized_file(h[:stdout], h[:working_dir]) if h[:stdout]
    h[:stderr] = Eye::System.normalized_file(h[:stderr], h[:working_dir]) if h[:stderr]
    h[:stdall] = Eye::System.normalized_file(h[:stdall], h[:working_dir]) if h[:stdall]

    h[:environment] = Eye::System.prepare_env(h)

    h
  end

  def c(name)
    @config[name]
  end

  def [](name)
    @config[name]
  end

  def update_config(new_config = {})
    new_config = prepare_config(new_config)
    @config = new_config
    @full_name = nil
    @logger = nil

    debug { "updating config to: #{@config.inspect}" }

    remove_triggers
    add_triggers

    if up?
      # rebuild checks for this process
      remove_watchers
      remove_children

      add_watchers
      add_children
    end
  end

  # is pid_file under Eye::Process control, or not
  def control_pid?
    !!self[:daemonize]
  end

end
