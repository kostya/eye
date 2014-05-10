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

  def retry_start_after_flapping
    return unless unmonitored?
    return unless state_reason.to_s.include?('flapping') # TODO: remove hackety

    schedule :start, Eye::Reason.new(:'retry start after flapping')
    self.flapping_times += 1
  end

private

  def add_trigger(cfg = {})
    trigger = Eye::Trigger.create(current_actor, cfg)
    self.triggers << trigger if trigger
  end

end
