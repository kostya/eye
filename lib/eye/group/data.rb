module Eye::Group::Data

  def status_data(opts = {})
    plist = @processes.map { |p| p.status_data(opts) }

    h = { name: name, type: :group, subtree: plist }

    h[:debug] = debug_data if opts[:debug]

    # show current chain
    if scheduled_call = @scheduled_call
      h[:current_command] = scheduled_call[:command]

      if (chain_commands = scheduler_commands_list) && chain_commands.present?
        h[:chain_commands] = chain_commands
      end

      if @chain_processes_current && @chain_processes_count
        h[:chain_progress] = [@chain_processes_current, @chain_processes_count]
      end
    end

    h
  end

  def status_data_short
    h = {}
    @processes.each do |p|
      state = p.state
      h[state] ||= 0
      h[state] += 1
    end
    { name: (@name == '__default__' ? 'default' : @name), type: :group, states: h }
  end

  def debug_data
    { queue: scheduler_commands_list, chain: chain_status }
  end

end
