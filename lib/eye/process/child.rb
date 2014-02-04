module Eye::Process::Child

  def add_children
    add_or_update_children
  end

  def add_or_update_children
    return unless self[:monitor_children]
    return unless self.up?
    return if @updating_children
    @updating_children = true

    unless self.pid
      warn "can't add children; pid not set"
      return
    end

    now_children = Eye::SystemResources.children(self.pid)
    new_children = []
    exist_children = []

    now_children.each do |child_pid|
      if self.children[child_pid]
        exist_children << child_pid
      else
        new_children << child_pid
      end
    end

    removed_children = self.children.keys - now_children

    if new_children.present?
      new_children.each do |child_pid|
        self.children[child_pid] = Eye::ChildProcess.new(child_pid, self[:monitor_children], logger.prefix)
      end
    end

    if removed_children.present?
      removed_children.each{|child_pid| remove_child(child_pid) }
    end

    h = {:new => new_children.size, :removed => removed_children.size, :exists => exist_children.size }
    debug "children info: #{ h.inspect }"

    @updating_children = false
    h
  end

  def remove_children
    if children.present?
      children.keys.each{|child_pid| remove_child(child_pid) }
    end
  end

  def remove_child(child_pid)
    child = self.children.delete(child_pid)
    child.destroy if child && child.alive?
  end

end
