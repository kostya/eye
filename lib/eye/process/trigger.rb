module Eye::Process::Trigger

  def add_triggers
    (self[:triggers] || {}).each_value { |cfg| add_trigger(cfg) }
  end

  def remove_triggers
    self.triggers = []
  end

  def check_triggers(transition)
    self.triggers.each { |trigger| trigger.notify(transition, @state_call) }
  end

  # conditional start, used in triggers, to start only from unmonitored state, and only if special reason
  def conditional_start
    unless unmonitored?
      warn "skip, because in state #{state_name}"
      return
    end

    state_by = @state_call.try(:[], :by)
    current_by = @scheduled_call.try(:[], :by)
    if state_by && current_by && state_by != current_by
      warn "skip, state_by(#{state_by}) != current_by(#{current_by})"
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
