module Eye::Process::Trigger

  def add_triggers
    if self[:triggers]
      self[:triggers].each do |_, cfg|
        add_trigger(cfg)
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
        @flapping = true        
      end
    end
  end

private

  def add_trigger(cfg = {})
    self.triggers << Eye::Trigger.create(cfg, @logger)
  end

end