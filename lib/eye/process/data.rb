module Eye::Process::Data

  # logger tag
  def full_name
    @full_name ||= [self[:application], (self[:group] == '__default__') ? nil : self[:group], self[:name]].compact.join(':')
  end

  def status_data(debug = false)
    p_st = self_status_data(debug)

    if childs.present?
      p_st.merge(:subtree => Eye::Utils::AliveArray.new(childs.values).map{|c| c.status_data(debug) } )
    elsif self[:monitor_children] && self.up?
      p_st.merge(:subtree => [{name: '=loading childs='}])
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
      h.merge!( state_changed_at: @states_history.last[:at],
                state_reason: @states_history.last[:reason] )
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
    self.childs.each { |_, child| return true if child == obj }
    false
  end

end
