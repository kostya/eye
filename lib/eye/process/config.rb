module Eye::Process::Config

  DEFAULTS = {
    :keep_alive => true, # restart when crushed
    :check_alive_period => 5.seconds,

    :start_timeout => 10.seconds,
    :stop_timeout => 5.seconds,
    :restart_timeout => 10.seconds,

    :start_grace => 2.5.seconds, 
    :stop_grace => 0.5.seconds, 
    :restart_grace => 0.5.seconds, 

    :daemonize => false,
    :auto_start => true, # auto start on monitor action

    :childs_update_period => 30.seconds
  }

  def prepare_config(new_config)
    h = DEFAULTS.merge(new_config)
    h[:pid_file_ex] = Eye::System.normalized_file(h[:pid_file], h[:working_dir]) if h[:pid_file]
    h[:checks] = {} if h[:checks].blank?
    h[:triggers] = {} if h[:triggers].blank?
    h[:childs_update_period] = h[:monitor_children][:childs_update_period] if h[:monitor_children] && h[:monitor_children][:childs_update_period]

    # check speedy flapping by default
    if h[:triggers].blank? || !h[:triggers][:flapping]
      h[:triggers] ||= {}
      h[:triggers][:flapping] = {:type => :flapping, :times => 10, :within => 10.seconds}
    end
    
    h[:stdout] = Eye::System.normalized_file(h[:stdout], h[:working_dir]) if h[:stdout]
    h[:stderr] = Eye::System.normalized_file(h[:stderr], h[:working_dir]) if h[:stderr]

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

    debug "update config to: #{@config.inspect}"

    remove_triggers
    add_triggers

    if up?
      # rebuild checks for this process
      from_up; on_up
    end    
  end

  # is pid_file under Eye::Process control, or not
  def control_pid?
    return self[:control_pid] unless self[:control_pid].nil?
    !!self[:daemonize]
  end
  
end
