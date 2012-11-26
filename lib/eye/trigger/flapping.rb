class Eye::Trigger::Flapping < Eye::Trigger

  # { :type => :flapping, :times => 2, :within => 30.seconds}

  params :times, :within

  def good?
    return true unless within

    states = @states_history.states_for_period( within )

    starting_count = states.count{|st| st == :starting}
    down_count = states.count{|st| st == :down}
    times_count = times || 5

    if (starting_count >= times_count) && (down_count >= times_count)
      false
    else
      true
    end
  end

end