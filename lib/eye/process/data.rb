module Eye::Process::Data

  def logger_tag
    full_name
  end

  def app_name
    self[:application]
  end

  def group_name
    self[:group] == '__default__' ? nil : self[:group]
  end

  def group_name_pure
    self[:group]
  end

  def full_name
    @full_name ||= [app_name, group_name, self[:name]].compact.join(':')
  end

  def status_data(opts = {})
    p_st = self_status_data(opts)

    if children.present?
      p_st.merge(subtree: Eye::Utils::AliveArray.new(children.values).map { |c| c.status_data(opts) })
    elsif self[:monitor_children] && self.up?
      p_st.merge(subtree: [{ name: '=loading children=' }])
    else
      # common state
      p_st
    end
  end

  def self_status_data(opts)
    h = { name: name,
          state: state,
          type: (self.class == Eye::ChildProcess ? :child_process : :process),
          resources: Eye::SystemResources.resources(pid) }

    if @states_history
      h[:state_changed_at] = @states_history.last_state_changed_at.to_i
      h[:state_reason] = @states_history.last_reason.to_s
    end

    h[:debug] = debug_data if opts[:debug]
    h[:procline] = Eye::SystemResources.args(self.pid) if opts[:procline]
    h[:current_command] = scheduler_current_command if scheduler_current_command

    h
  end

  def debug_data
    { queue: scheduler_actions_list, watchers: @watchers.keys, timers: timers_data }
  end

  def timers_data
    if actor = Thread.current[:celluloid_actor]
      actor.timers.timers.map(&:interval)
    end
  rescue
    []
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
