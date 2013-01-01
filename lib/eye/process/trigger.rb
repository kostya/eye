module Eye::Process::Trigger

  def add_triggers
    if self[:triggers]
      self[:triggers].each do |type, cfg|
        add_trigger(cfg) unless self[:notriggers].try(:[], type)
      end      
    end
  end

  def remove_triggers
    self.triggers = []
  end

  def check_triggers
    return if self.state_name == :unmonitored

    self.triggers.each do |trigger|
      if !trigger.check(self.states_history)
        notify :crit, "Process #{full_name} flapping!"
        @flapping = true        
      end
    end
  end

private

  def add_trigger(cfg = {})
    self.triggers << Eye::Trigger.create(cfg, logger.prefix)
  end

end