class Eye::Process::StatesHistory < Eye::Utils::Tail

  def push(state, reason = nil, tm = Time.now)
    super(state: state, at: tm.to_i, reason: reason)
  end

  def states
    self.map{|c| c[:state] }
  end

  def states_for_period(period, from_time = nil)
    tm = Time.now - period
    tm = [tm, from_time].max if from_time
    tm = tm.to_f
    self.select{|s| s[:at] >= tm }.map{|c| c[:state] }
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

  def seq?(*seq)
    str = states * ','
    substr = seq.flatten * ','
    str.include?(substr)
  end

  def end?(*seq)
    str = states * ','
    substr = seq.flatten * ','
    str.end_with?(substr)
  end

  def any?(*seq)
    states.any? do |st|
      seq.flatten.include?(st)
    end
  end

  def noone?(*seq)
    !states.all? do |st|
      seq.flatten.include?(st)
    end
  end

  def all?(*seq)
    states.all? do |st|
      seq.flatten.include?(st)
    end
  end

  def state_count(state)
    states.count do |st|
      st == state
    end
  end

end