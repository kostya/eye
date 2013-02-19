module Eye::Group::Chain

private

  def chain_schedule(type, grace, command, *args)
    info "start #{type} with #{grace}s chain #{command} #{args}"

    @chain_processes_count = @processes.size
    @chain_processes_current = 0

    @processes.each do | process |
      chain_schedule_process(process, type, command, *args)

      @chain_processes_current = @chain_processes_current.to_i + 1

      # to skip last sleep
      break if @chain_processes_current.to_i == @chain_processes_count.to_i 

      # wait next process
      sleep grace.to_f
    end

    @chain_processes_count = nil
    @chain_processes_current = nil
  end

  def chain_schedule_process(process, type, command, *args)
    if type == :sync
      # sync command, with waiting
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