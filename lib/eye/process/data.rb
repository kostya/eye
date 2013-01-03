module Eye::Process::Data

  # logger tag
  def full_name
    @full_name ||= [self[:application], (self[:group] == '__default__') ? nil : self[:group], self[:name]].compact.join(':')
  end

  def status_data(debug = false)
    p_st = self_status_data(debug)

    if childs.present?
      p_st.merge(:subtree => childs.values.map{|c| c.status_data(debug) if c.alive? }.compact)
    elsif self[:monitor_children] && self.state_name == :up
      p_st.merge(:subtree => [{:name => "=loading childs="}])
    else
      # common state
      p_st
    end
  end

  def self_status_data(debug = false)
    { 
      :name => name, 
      :pid => pid, 
      :state => state, 
      :debug => debug ? debug_data : nil,
      :resources => Eye::SystemResources.resources(pid)
    }    
  end

  def debug_data
    {:queue => scheduler.names_list, :watchers => @watchers.keys}
  end

end
