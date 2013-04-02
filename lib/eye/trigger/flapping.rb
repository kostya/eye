class Eye::Trigger::Flapping < Eye::Trigger

  # triggers :flapping, :times => 10, :within => 1.minute, 
  #          :retry_in => 10.minutes

  param :times, [Fixnum], true, 5
  param :within, [Float, Fixnum], true
  param :retry_in, [Float, Fixnum]

  def initialize(*args)
    super
    @last_at = nil
  end

  def good?
    states = @states_history.states_for_period( within, @last_at )

    starting_count = states.count{|st| st == :starting }
    down_count = states.count{|st| st == :down }

    if (starting_count >= times) && (down_count >= times)
      @last_at = @states_history.last_state_changed_at
      false
    else
      true
    end
  end

end