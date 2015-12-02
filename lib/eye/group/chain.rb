module Eye::Group::Chain

private

  def chained_call(call)
    type, grace = chain_options(call[:command])

    syncer = call[:syncer] || @last_scheduled_call.try(:[], :syncer)
    Eye::Utils::Syncer.cast(syncer).wait_group(false) do |syncer_group|
      chain_schedule(type, grace, call, syncer_group)
    end
  end

  def chain_schedule(type, grace, call, syncer_group = nil)
    command = call[:command]
    args = call[:args]
    info "starting #{type} with #{grace}s chain #{command} #{args}"

    @chain_processes_count = @processes.size
    @chain_processes_current = 0
    @chain_breaker = false

    started_at = Time.now

    @processes.each do |process|
      if process.skip_group_action?(command)
        @chain_processes_current = @chain_processes_current.to_i + 1
        next
      end

      chain_schedule_process(process, type, call, syncer_group)

      @chain_processes_current = @chain_processes_current.to_i + 1

      # to skip last sleep
      break if @chain_processes_current.to_i == @chain_processes_count.to_i
      break if @chain_breaker

      # wait next process
      sleep grace.to_f

      break if @chain_breaker
    end

    debug { "chain finished #{Time.now - started_at}s" }

    @chain_processes_count = nil
    @chain_processes_current = nil
  end

  def chain_schedule_process(process, type, call, syncer_group)
    debug { "chain_schedule_process #{process.name} #{type} #{call[:command]}" }

    if type == :sync
      process.sync_call(call)
    else
      process.send_call(call.merge(syncer: syncer_group.child))
    end
  end

  def chain_status
    if @config[:chain]
      [:start, :restart].map { |c| @config[:chain][c].try(:[], :grace) }
    end
  end

  # with such delay will chained processes by default
  DEFAULT_CHAIN = 0.2

  def chain_options(command)
    command = :start if command == :monitor # HACK: for monitor command, work as start

    if @config[:chain] && @config[:chain][command]
      type = @config[:chain][command].try :[], :type
      type = [:async, :sync].include?(type) ? type : :async

      grace = @config[:chain][command].try :[], :grace
      grace = (grace || DEFAULT_CHAIN).to_f rescue DEFAULT_CHAIN

      [type, grace]
    else
      # default chain case
      [:async, DEFAULT_CHAIN]
    end
  end

end
