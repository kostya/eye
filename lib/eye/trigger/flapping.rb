class Eye::Trigger::Flapping < Eye::Trigger

  # trigger :flapping, :times => 10, :within => 1.minute,
  #         :retry_in => 10.minutes, :retry_times => 15

  param :times, [Integer], true, 5
  param :within, [Float, Integer], true
  param :retry_in, [Float, Integer]
  param :retry_times, [Integer]
  param :reretry_in, [Float, Integer]
  param :reretry_times, [Integer]

  def initialize(*args)
    super
    clear_counters
  end

  def check(transition)
    on_flapping if transition.event == :crashed && !good?
  end

private

  def clear_counters
    @retry_times = 0
    @reretry_times = 0
  end

  def good?
    down_count = 0
    process.states_history.states_for_period(within, @last_at) do |s|
      down_count += 1 if s[:state] == :down
    end

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
    process.schedule command: :unmonitor, by: :flapping

    return unless retry_in
    if !retry_times || (retry_times && @retry_times < retry_times)
      @retry_times += 1
      process.schedule(in: retry_in.to_f, command: :conditional_start,
                       by: :flapping, reason: 'retry start after flapping')
    elsif reretry_in && !reretry_times || (reretry_times && @reretry_times < reretry_times)
      @retry_times = 0
      @reretry_times += 1
      process.schedule(in: reretry_in.to_f, command: :conditional_start,
                       by: :flapping, reason: 'reretry start after flapping')
    end
  end

end
