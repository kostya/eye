module Eye::Dsl::Validate

  # validate global config rules
  def validate(config)
    all_processes = config.values.map{|e| (e[:groups] || {}).values.map{|c| (c[:processes] || {}).values} }.flatten

    # Check blank pid_files
    
    no_pid_file = all_processes.select{|c| c[:pid_file].blank? }
    if no_pid_file.present?
      raise Eye::Dsl::Error, "blank pid_file for: #{no_pid_file.map{|c| c[:name]} * ', '}"
    end

    # Check dublicates of the full pid_file

    dubl_pids = all_processes.each_with_object(Hash.new(0)) do |o, h| 
      ex_pid_file = Eye::System.normalized_file(o[:pid_file], o[:working_dir])
      h[ex_pid_file] += 1
    end
    dubl_pids = dubl_pids.select{|k,v| v>1}

    if dubl_pids.present?
      raise Eye::Dsl::Error, "dublicate pid_files: #{dubl_pids.inspect}"
    end

    # Check dublicates of the full_name
    dubl_names = all_processes.each_with_object(Hash.new(0)) do |o, h| 
      full_name = "#{o[:application]}:#{o[:group]}:#{o[:name]}"
      h[full_name] += 1
    end
    dubl_names = dubl_names.select{|k,v| v>1}

    if dubl_names.present?
      raise Eye::Dsl::Error, "dublicate names: #{dubl_names.inspect}"
    end
  end

end