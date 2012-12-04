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
    :auto_start => true,

    :clear_pid_file => nil,

    :childs_update_period => 30.seconds
  }

  def prepare_config(new_config)
    h = DEFAULTS.merge(new_config)
    h[:pid_file_ex] = Eye::System.normalized_file(h[:pid_file], h[:working_dir]) if h[:pid_file]
    h[:checks] = {} if h[:checks].blank?
    h[:triggers] = {} if h[:triggers].blank?
    h[:clear_pid_file] = true if h[:clear_pid_file].nil? && h[:daemonize]
    h[:childs_update_period] = h[:monitor_children][:childs_update_period] if h[:monitor_children] && h[:monitor_children][:childs_update_period]

    # check speedy flapping by default
    if h[:triggers].blank? || !h[:triggers][:flapping]
      h[:triggers] ||= {}
      h[:triggers][:flapping] = {:type => :flapping, :times => 10, :within => 10.seconds}
    end

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

    remove_watchers
    remove_triggers
    remove_childs

    add_triggers!

    # bad style code!
    if state_name == :up
      add_watchers!
      add_childs!
    end    
  end
  
end
