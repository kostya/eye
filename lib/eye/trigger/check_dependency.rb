class Eye::Trigger::CheckDependency < Eye::Trigger
  param :names, [Array], true, 5

  def check(transition)
    check_dependency(transition.to_name) if transition.from_name == :up
  end

private

  def check_dependency(to)
    processes = names.map do |name|
      Eye::Control.find_nearest_process(name, process.group_name_pure, process.app_name)
    end.compact
    return if processes.empty?
    processes = Eye::Utils::AliveArray.new(processes)

    act = case to
      when :down, :restarting; :restart
      when :stopping; :stop
      when :unmonitored; :unmonitor
    end

    if act
      processes.each do |p|
        p.schedule act, Eye::Reason.new(:"#{act} dependecies")
      end
    end
  end

end
