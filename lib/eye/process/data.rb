module Eye::Process::Data

  def logger_tag
    full_name
  end

  def app_name
    self[:application]
  end

  def group_name
    (self[:group] == '__default__') ? nil : self[:group]
  end

  def group_name_pure
    self[:group]
  end

  def full_name
    @full_name ||= [app_name, group_name, self[:name]].compact.join(':')
  end

  def status_data(debug = false)
    p_st = self_status_data(debug)

    if children.present?
      p_st.merge(:subtree => Eye::Utils::AliveArray.new(children.values).map{|c| c.status_data(debug) } )
    elsif self[:monitor_children] && self.up?
      p_st.merge(:subtree => [{name: '=loading children='}])
    else
      # common state
      p_st
    end
  end

  def self_status_data(debug = false)
    h = { name: name, state: state,
          type: (self.class == Eye::ChildProcess ? :child_process : :process),
          resources: Eye::SystemResources.resources(pid) }

    if @states_history
      h.merge!( state_changed_at: @states_history.last_state_changed_at.to_i,
                state_reason: @states_history.last_reason )
    end

    h.merge!(debug: debug_data) if debug
    h.merge!(current_command: current_scheduled_command) if current_scheduled_command

    h
  end

  def debug_data
    { queue: scheduler_actions_list, watchers: @watchers.keys }
  end

  def sub_object?(obj)
    return false if self.class == Eye::ChildProcess
    self.children.each { |_, child| return true if child == obj }
    false
  end

  def environment_string
    s = []
    @config[:environment].each { |k, v| s << "#{k}=#{v}" }
    s * ' '
  end

  def shell_string(dir = true)
    str = ''
    str += "cd #{self[:working_dir]} && " if dir
    str += environment_string
    str += ' '
    str += self[:start_command]
    str += ' &' if self[:daemonize]
    str
  end

end
