class Eye::Process::StatesHistory < Eye::Utils::Tail

  def push(state, reason = nil, tm = Time.now)
    super(state: state, at: tm.to_i, reason: reason)
  end

  def states
    self.map { |c| c[:state] }
  end

  def states_for_period(period, from_time = nil, &block)
    tm = Time.now - period
    tm = [tm, from_time].max if from_time
    tm = tm.to_f
    if block
      self.each { |s| yield(s) if s[:at] >= tm }
    else
      self.select { |s| s[:at] >= tm }.map { |c| c[:state] }
    end
  end

  def last_state
    last[:state]
  end

  def last_reason
    last[:reason] rescue nil
  end

  def last_state_changed_at
    Time.at(last[:at])
  end

end
