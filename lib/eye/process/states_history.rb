class Eye::Process::StatesHistory < Eye::Utils::Tail

  def push(state, tm = Time.now)
    super(state: state, at: tm)
  end

  def states
    self.map{|c| c[:state] }
  end

  def states_for_period(period)
    tm = Time.now - period
    self.select do |s|
      s[:at] >= tm
    end.map{|c| c[:state] }
  end

  def last_state
    last[:state]
  end

  def last_state_changed_at
    last[:at]
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