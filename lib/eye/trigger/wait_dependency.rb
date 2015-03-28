class Eye::Trigger::WaitDependency < Eye::Trigger::StartingGuard
  param :names, [Array], true
  param :should_start, [TrueClass, FalseClass]

  param_default :every, 0.2
  param_default :times, 7
  param_default :retry_in, 1.minute
  param_default :retry_times, 5

private

  def guard
    if (@retry_count == 0 || @reason.class != Eye::Reason::StartingGuard)
      processes = names.map do |name|
        Eye::Control.find_nearest_process(name, process.group_name_pure, process.app_name)
      end.compact
      return if processes.empty?
      @processes = Eye::Utils::AliveArray.new(processes)

      try_start if (should_start == nil || should_start)
    end

    res = true
    @processes.pmap do |p|
      info { "wait for #{p.full_name} until it :up" }
      res &= process.wait_for_condition(2.seconds, 0.2) { p.state_name == :up }
    end
    res
  end

  def try_start
    @processes.each do |p|
      if p.state_name != :up
        p.schedule :start, Eye::Reason.new(:start_dependency)
      end
    end
  end

end
