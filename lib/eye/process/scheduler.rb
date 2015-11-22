module Eye::Process::Scheduler

  # ex: schedule :update_config, config, "reason: update_config"
  def schedule(command, *args, &block)
    if scheduler_freeze?
      warn ":#{command} ignoring to schedule, because scheduler is freeze"
      return
    end

    unless self.respond_to?(command, true)
      warn ":#{command} scheduling is unsupported"
      return
    end

    reason = args.pop if args.present? && args[-1].is_a?(Eye::Reason)

    info "schedule :#{command} #{reason ? "(reason: #{reason})" : nil}"

    if reason.class == Eye::Reason
      # for auto reasons
      # skip already running commands and all in chain
      scheduler_add_wo_dups_current(:scheduled_action, command, args: args, reason: reason, block: block)
    else
      # for manual, or without reason
      # skip only for last in chain
      scheduler_add_wo_dups(:scheduled_action, command, args: args, reason: reason, block: block)
    end
  end

  def schedule_in(interval, command, *args, &block)
    debug { "schedule_in #{interval} :#{command} #{args}" }
    after(interval.to_f) do
      debug { "scheduled_in #{interval} :#{command} #{args}" }
      schedule(command, *args, &block)
    end
  end

  def scheduled_action(command, h = {})
    reason = h[:reason]
    info "=> #{command} #{h[:args].present? ? "#{h[:args] * ','}" : nil} #{reason ? "(reason: #{reason})" : nil}"

    @current_scheduled_command = command
    @last_scheduled_command = command
    @last_scheduled_reason = reason
    @last_scheduled_at = Time.now

    send(command, *h[:args], &h[:block])
    @current_scheduled_command = nil
    info "<= #{command}"

    schedule_history.push(command, reason, @last_scheduled_at.to_i)

    if parent = self.try(:parent)
      parent.schedule_history.push("#{command}_child", reason, @last_scheduled_at.to_i)
    end
  end

  def execute_proc(*_args, &block)
    self.instance_exec(&block)
  rescue Object => ex
    log_ex(ex)
  end

  def scheduler_actions_list
    scheduler_calls.map { |c| c[:args].first rescue nil }.compact
  end

  def scheduler_clear_pending_list
    scheduler_calls.clear
  end

  def self.included(base)
    base.execute_block_on_receiver :schedule
  end

  attr_accessor :current_scheduled_command
  attr_accessor :last_scheduled_command, :last_scheduled_reason, :last_scheduled_at

  def schedule_history
    @schedule_history ||= Eye::Process::StatesHistory.new(50)
  end

  def scheduler_freeze
    @scheduler_freeze = true
  end

  def scheduler_unfreeze
    @scheduler_freeze = nil
  end

  def scheduler_freeze?
    @scheduler_freeze
  end

  # ================================================
  # Scheduler methods

  def scheduler_add(method_name, *args)
    scheduler_calls << { method_name: method_name, args: args }
    ensure_scheduler_process
  end

  def scheduler_add_wo_dups(method_name, *args)
    h = { method_name: method_name, args: args }
    if scheduler_calls[-1] != h
      scheduler_calls << h
      ensure_scheduler_process
    end
  end

  def scheduler_add_wo_dups_current(method_name, *args)
    h = { method_name: method_name, args: args }
    if !scheduler_calls.include?(h) && @scheduler_call != h
      scheduler_calls << h
      ensure_scheduler_process
    end
  end

  def scheduler_calls
    @scheduler_calls ||= []
  end

  def ensure_scheduler_process
    unless @scheduler_running
      @scheduler_running = true
      async.process_scheduler
    end
  end

  def process_scheduler
    while @scheduler_call = scheduler_calls.shift
      @scheduler_running = true
      self.send(@scheduler_call[:method_name], *@scheduler_call[:args])
    end
    @scheduler_running = false
  end

end
