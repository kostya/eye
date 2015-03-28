class Eye::Trigger::Flapping < Eye::Trigger

  # trigger :flapping, :times => 10, :within => 1.minute,
  #         :retry_in => 10.minutes, :retry_times => 15

  param :times, [Fixnum], true, 5
  param :within, [Float, Fixnum], true
  param :retry_in, [Float, Fixnum]
  param :retry_times, [Fixnum]

  def initialize(*args)
    super
    @flapping_times = 0
  end

  def check(transition)
    on_flapping if transition.event == :crashed && !good?
  end

private

  def good?
    states = process.states_history.states_for_period( within, @last_at )
    down_count = states.count{|st| st == :down }

    if down_count >= times
      @last_at = process.states_history.last_state_changed_at
      false
    else
      true
    end
  end

  def on_flapping
    debug { 'flapping recognized!!!' }

    process.notify :error, 'flapping!'
    process.schedule :unmonitor, Eye::Reason::Flapping.new(:flapping)

    return unless retry_in
    return if retry_times && @flapping_times >= retry_times

    @flapping_times += 1
    process.schedule_in(retry_in.to_f, :conditional_start, Eye::Reason::Flapping.new('retry start after flapping'))
  end

end
