module Eye::Group::Chain

private

  def chain_schedule(type, grace, command, *args)
    info "starting #{type} with #{grace}s chain #{command} #{args}"

    @chain_processes_count = @processes.size
    @chain_processes_current = 0
    @chain_breaker = false

    started_at = Time.now

    @processes.each do | process |
      chain_schedule_process(process, type, command, *args)

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

  def chain_schedule_process(process, type, command, *args)
    debug { "chain_schedule_process #{process.name} #{type} #{command}" }

    if type == :sync
      # sync command, with waiting
      # this is very hackety, because call method of the process without its scheduler
      # need to provide some scheduler future
      process.last_scheduled_reason = self.last_scheduled_reason
      process.send(command, *args)
    else
      # async command
      process.send_command(command, *args)
    end
  end

  def chain_status
    if @config[:chain]
      [:start, :restart].map{|c| @config[:chain][c].try(:[], :grace) }
    end
  end

  def chain_command(command, *args)
    chain_opts = chain_options(command)
    chain_schedule(chain_opts[:type], chain_opts[:grace], command, *args)
  end

  # with such delay will chained processes by default
  DEFAULT_CHAIN = 0.2

  def chain_options(command)
    command = :start if command == :monitor # hack for monitor command, work as start

    if @config[:chain] && @config[:chain][command]
      type = @config[:chain][command].try :[], :type
      type = [:async, :sync].include?(type) ? type : :async

      grace = @config[:chain][command].try :[], :grace
      grace = grace ? (grace.to_f rescue DEFAULT_CHAIN) : DEFAULT_CHAIN

      {:type => type, :grace => grace}
    else
      # default chain case
      {:type => :async, :grace => DEFAULT_CHAIN}
    end
  end

end
