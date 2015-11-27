module Eye::Group::Call

  # :update_config, :start, :stop, :restart, :unmonitor, :monitor, :break_chain, :delete, :signal, :user_command
  def send_call(call)
    info "call: #{call[:method]}"

    case call[:command]
      when :delete
        delete
      when :break_chain
        break_chain
      else
        user_schedule(call)
    end
  end

  def update_config(cfg)
    @config = cfg
    @full_name = nil
  end

  def start
    chained_call command: :start
  end

  def stop
    fast_call command: :stop
  end

  def restart
    chained_call command: :restart
  end

  def delete
    fast_call command: :delete
    terminate
  end

  def monitor
    chained_call command: :monitor
  end

  def unmonitor
    fast_call command: :unmonitor
  end

  def signal(sig)
    fast_call command: :signal, args: [sig]
  end

  def user_command(cmd)
    fast_call command: :user_command, args: [cmd]
  end

  def break_chain
    info 'break chain'
    scheduler_clear_pending_list
    @chain_breaker = true
  end

private

  def fast_call(call)
    command = call[:command]
    args = call[:args]
    info "send to all processes #{command} #{args.present? ? args * ',' : nil}"

    @processes.each do |process|
      process.send_call(call) unless process.skip_group_action?(command)
    end
  end

end
