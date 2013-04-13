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
        on_flapping(trigger) if trigger.class == Eye::Trigger::Flapping
      end
    end
  end

private

  def add_trigger(cfg = {})
    trigger = Eye::Trigger.create(cfg, logger.prefix)
    self.triggers << trigger
  end

  def on_flapping(trigger)
    notify :crit, 'flapping!'
    schedule :unmonitor, "flapping"

    @retry_times ||= 0
    retry_in = trigger.retry_in

    return unless retry_in
    return if trigger.retry_times && @retry_times >= trigger.retry_times

    schedule_in(retry_in.to_f, :retry_action)
  end

  def retry_action
    debug "trigger retry timer"
    return unless unmonitored?
    return unless state_reason.to_s.include?('flapping') # TODO: remove hackety

    schedule :start, "retry start after flapping"
    @retry_times += 1
  end

end
