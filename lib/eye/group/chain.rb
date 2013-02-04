module Eye::Group::Chain

private

  def chain_schedule(type, command, grace = 0)
    info "start #{type} chain #{command} with #{grace}s"

    @chain_processes_count = @processes.size
    @chain_processes_current = 0

    @processes.each_with_index do | process, ind |
      @chain_processes_current = @chain_processes_current.to_i + 1

      chain_schedule_process(process, type, command)

      break if ind + 1 == @chain_processes_count.to_i # to not sleep after last process

      # wait next process
      sleep grace.to_f
    end

    @chain_processes_count = nil
    @chain_processes_current = nil
  end

  def chain_schedule_process(process, type, command)
    return unless process.alive?

    if type == :sync
      # sync command, with waiting
      process.send(command)
    else
      # async command
      process.send_command(command)
    end
  end

  def chain_status
    if @config[:chain]
      [:start, :restart].map{|c| @config[:chain][c].try(:[], :grace) }
    end
  end

  def chain_command(command)
    chain_opts = chain_options(command)
    chain_schedule(chain_opts[:type], command, chain_opts[:grace])
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