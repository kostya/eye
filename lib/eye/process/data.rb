module Eye::Process::Data

  # logger tag
  def full_name
    @full_name ||= [self[:application], (self[:group] == '__default__') ? nil : self[:group], self[:name]].compact.join(':')
  end

  def status_string
    res = ["#{self[:name]}(#{pid}): #{state}\n"]

    if self.childs.present?
      self.childs.each do |_, child|
        res << ("  " + child.status_string)
      end
    elsif self[:monitor_children] && self.state_name == :up
      res << "  ... loading childs"
    end

    res
  end

end
