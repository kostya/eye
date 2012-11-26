module Eye::Dsl::Validate

  def validate(config)
    all_processes = config.values.map{|e| e[:groups].values.map{|c| c[:processes].values} }.flatten
    
    no_pid_file = all_processes.select{|c| c[:pid_file].blank? }
    if no_pid_file.present?
      raise Eye::Dsl::Error, "has no pid_file for #{no_pid_file.map{|c| c[:name]}.inspect}"
    end
    
    pids = all_processes.map{|c| c[:pid_file] }
    if pids.size != pids.uniq.size
      raise Eye::Dsl::Error, "dublicates of the pid_file"
    end

    pids = all_processes.map{|c| c[:name] }
    if pids.size != pids.uniq.size
      raise Eye::Dsl::Error, "dublicates of the names processes"
    end
  end

end