module Eye::Process::Trigger

  def add_triggers
    if self[:triggers]
      self[:triggers].each do |type, cfg|
        add_trigger(cfg)
      end      
    end
  end

  def remove_triggers
    self.triggers = []
  end

  def check_triggers
    return if unmonitored?

    self.triggers.each do |trigger|
      unless trigger.check(self.states_history)

        if trigger.class == Eye::Trigger::Flapping
          notify :crit, 'flapping!'
          schedule :unmonitor, "flapping"
        end
      end
    end
  end

private

  def add_trigger(cfg = {})
    trigger = Eye::Trigger.create(cfg, logger.prefix)
    self.triggers << trigger
  end

end
