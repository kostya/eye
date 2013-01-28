module Eye::Process::SchedulerHack

  def scheduled_action(command, *args, &block)
    super

    schedule_history << command
  end

  def schedule_history
    @schedule_history ||= Eye::Process::StatesHistory.new(100)
  end

end

Eye::Process.send :include, Eye::Process::SchedulerHack
Eye::Group.send :include, Eye::Process::SchedulerHack