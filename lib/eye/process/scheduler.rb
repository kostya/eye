module Eye::Process::Scheduler

  def schedule(command, *args, &block)
    if scheduler.alive?
      info "schedule :#{command}"
      scheduler.add_wo_dups(:scheduled_action, command, *args, &block) 
    end
  end

  def scheduled_action(command, *args, &block)    
    info "=> #{command} #{args}"
    @current_scheduled_command = command
    send(command, *args, &block)
    @current_scheduled_command = nil
    info "<= #{command}"
  end

  def scheduler_actions_list
    scheduler.list.map{|c| c[:args].first rescue nil }.compact
  end

  def finalize
    remove_scheduler
  end

  attr_accessor :current_scheduled_command

private

  def remove_scheduler
    @scheduler.terminate if @scheduler && @scheduler.alive?
  end

  def scheduler
    @scheduler ||= Celluloid::Chain.new(current_actor)
  end

end