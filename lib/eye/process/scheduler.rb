module Eye::Process::Scheduler

  # Call params:
  # :command
  # :args
  # :by
  # :reason
  # :block
  # :signal
  # :at
  # :in

  # :update_config, :start, :stop, :restart, :unmonitor, :monitor, :break_chain, :delete, :signal, :user_command
  def send_call(call)
    user_schedule(call)
  end

  def user_schedule(call)
    call[:by] ||= :user
    internal_schedule(call)
  end

  # 2 Forms of schedule:
  # schedule command: 'bla', args: [1, 2, 3]
  # schedule :bla, 1, 2, 3
  def schedule(*args)
    if args[0].is_a?(Hash)
      internal_schedule(args[0])
    else
      internal_schedule(command: args[0], args: args[1..-1])
    end
  end

  def internal_schedule(call)
    if interval = call[:in]
      debug { "schedule_in #{interval} :#{call[:command]}" }
      after(interval.to_f) do
        debug { "scheduled_in #{interval} :#{call[:command]}" }
        call[:in] = nil
        internal_schedule(call)
      end
      return
    end

    call[:at] ||= Time.now.to_i
    command = call[:command]

    @scheduler_freeze = false if call[:freeze] == false

    if @scheduler_freeze
      warn ":#{command} ignoring to schedule, because scheduler is freezed"
      return
    end

    unless self.respond_to?(command, true)
      warn ":#{command} scheduling is unsupported"
      return
    end

    if filter_call(call)
      info "schedule :#{command} (#{reason_from_call(call)})"
      scheduler_add(call)
    else
      info "not scheduled: #{command} (#{reason_from_call(call)})"
    end

    @scheduler_freeze = true if call[:freeze] == true
  end

  def scheduler_consume(call)
    args = call[:args]
    reason_str = reason_from_call(call)
    info "=> #{call[:command]} #{args.present? ? args.join(',') : nil} (#{reason_str})"
    send(call[:command], *args, &call[:block])

    history_cmd = is_a?(Eye::ChildProcess) ? "#{call[:command]}_child" : call[:command]
    scheduler_history.push(history_cmd, reason_str, call[:at])

  rescue Object => ex
    raise(ex) if ex.class == Celluloid::TaskTerminated
    log_ex(ex)

  ensure
    # signaling to waiter
    call[:signal].try :signal

    info "<= #{call[:command]}"
  end

  def filter_call(call)
    # for auto reasons, compare call with current @scheduled_call
    return false if call[:by] != :user && equal_action_call?(@scheduled_call, call)

    # check any equal call in queue scheduler_calls
    scheduler_calls.none? { |c| equal_action_call?(c, call) }
  end

  def equal_action_call?(call1, call2)
    call1 && call2 && (call1[:command] == call2[:command]) && (call1[:args] == call2[:args]) && (call1[:block] == call2[:block])
  end

  def scheduler_calls
    @scheduler_calls ||= []
  end

  def scheduler_history
    @scheduler_history ||= Eye::Process::StatesHistory.new(50)
  end

  def scheduler_add(call)
    scheduler_calls << call
    ensure_scheduler_process
  end

  def ensure_scheduler_process
    unless @scheduler_running
      @scheduler_running = true
      async.scheduler_run
    end
  end

  def scheduler_run
    while @scheduled_call = scheduler_calls.shift
      @scheduler_running = true
      @last_scheduled_call = @scheduled_call
      scheduler_consume(@scheduled_call)
    end
    @scheduler_running = false
  end

  def scheduler_commands_list
    scheduler_calls.map { |c| c[:command] }
  end

  def scheduler_clear_pending_list
    scheduler_calls.clear
  end

  def scheduler_last_command
    @last_scheduled_call.try :[], :command
  end

  def scheduler_last_reason
    reason_from_call(@last_scheduled_call)
  end

  def scheduler_current_command
    @scheduled_call.try :[], :command
  end

private

  def reason_from_call(call)
    return unless call

    if msg = call[:reason]
      msg.to_s
    elsif call[:by]
      "#{call[:command]} by #{call[:by]}"
    end
  end

end
