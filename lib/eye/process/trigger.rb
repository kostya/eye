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

  def check_triggers(transition)
    self.triggers.each { |trigger| trigger.notify(transition, state_reason) }
  end

  # conditional start, used in triggers, to start only from unmonitored state, and only if special reason
  def conditional_start
    unless unmonitored?
      warn "skip, because in state #{state_name}"
      return
    end

    previous_reason = state_reason
    if last_scheduled_reason && previous_reason && last_scheduled_reason.class != previous_reason.class
      warn "skip, last_scheduled_reason(#{last_scheduled_reason.inspect}) != previous_reason(#{previous_reason})"
      return
    end

    start
  end

private

  def add_trigger(cfg = {})
    trigger = Eye::Trigger.create(current_actor, cfg)
    self.triggers << trigger if trigger
  end

end
