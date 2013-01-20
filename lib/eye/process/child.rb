module Eye::Process::Child

  def add_childs
    add_or_update_childs
  end

  def add_or_update_childs
    return unless self[:monitor_children]

    return unless self.up?

    unless self.pid
      warn 'Cant add childs, because no pid'
      return
    end

    now_childs = Eye::SystemResources.childs(self.pid)
    new_childs = []
    exist_childs = []

    now_childs.each do |child_pid|
      if self.childs[child_pid]
        exist_childs << child_pid
      else
        new_childs << child_pid
      end
    end

    removed_childs = self.childs.keys - now_childs

    if new_childs.present?
      new_childs.each do |child_pid|
        self.childs[child_pid] = Eye::ChildProcess.new(child_pid, self[:monitor_children], logger.prefix)
      end      
    end

    if removed_childs.present?
      removed_childs.each do |child_pid|
        child = self.childs.delete(child_pid)
        child.delete if child && child.alive?
      end      
    end

    h = {:new => new_childs.size, :removed => removed_childs.size, :exists => exist_childs.size }
    debug "childs info: #{ h.inspect }"

    h
  end

  def remove_childs
    if childs.present?
      childs.keys.each do |child_pid|
        child = childs.delete(child_pid)
        child.delete if child && child.alive?
      end
    else
      debug 'No childs to clear'
    end
  end

end