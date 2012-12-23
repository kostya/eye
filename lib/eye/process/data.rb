module Eye::Process::Data

  # logger tag
  def full_name
    @full_name ||= [self[:application], (self[:group] == '__default__') ? nil : self[:group], self[:name]].compact.join(':')
  end

  def status_string
    n_ = self[:name].ljust(28)
    p_ = "(#{pid})".ljust(7)
    res = ["#{n_}#{p_}: #{state}\n"]
    #res = ["#{self[:name]}(#{pid}): #{state}\n"]

    if self.childs.present?
      self.childs.each do |_, child|
        res << ("  " + child.status_string)
      end
    elsif self[:monitor_children] && self.state_name == :up
      res << "  ... loading childs"
    end

    res
  end

  def status_data(debug = false)
    p_st = {:name => name, 
      :pid => pid, 
      :state => state, 
      :debug => debug ? debug_string : nil,
      :resources => Eye::SystemResources.info_string(pid)
    }

    if childs.present?
      p_st.merge(:subtree => childs.values.map{|c| c.status_data(debug)})
    elsif self[:monitor_children] && self.state_name == :up
      p_st.merge(:subtree => [{:name => "=loading childs="}])
    else
      # common state
      p_st
    end
  end

  def debug_string
    q = "q(" + @queue.names_list * ',' + ")"
    w = "w(" + @watchers.keys * ',' + ")"

    [w, q] * '; '
  end

end
