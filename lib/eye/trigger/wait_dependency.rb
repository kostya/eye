class Eye::Trigger::WaitDependency < Eye::Trigger
  param :names, [Array], true
  param :wait_timeout, [Numeric], nil, 15.seconds
  param :retry_after, [Numeric], nil, 1.minute
  param :should_start, [TrueClass, FalseClass]

  def check(transition)
    wait_dependency if transition.to_name == :starting
  end

private

  def wait_dependency
    # TODO: Alive array here
    processes = names.map { |name| Eye::Control.process_by_name(name) }.compact
    return if processes.empty?

    processes.each do |p|
      if p.state_name != :up && (should_start == nil || should_start)
        p.schedule :start, Eye::Reason.new(:start_dependency)
      end
    end

    res = true

    processes.pmap do |p|
      name = p.name

      res &= process.wait_for_condition(wait_timeout, 0.5) do
        info "wait for #{name} until it :up"
        p.state_name == :up
      end
    end

    unless res
      warn "not waited for #{names} to be up"
      process.switch :unmonitoring

      if retry_after
        process.schedule_in retry_after, :start, Eye::Reason.new(:wait_dependency)
      end

      raise Eye::Process::StateError.new('stop transition because dependency is not up')
    end
  end

end
