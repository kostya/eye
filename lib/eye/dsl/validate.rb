module Eye::Dsl::Validate

  # validate global config rules
  def validate(config)
    all_processes = config.values.map{|e| e[:groups].values.map{|c| c[:processes].values} }.flatten
    
    no_pid_file = all_processes.select{|c| c[:pid_file].blank? }
    if no_pid_file.present?
      raise Eye::Dsl::Error, "blank pid_file for: #{no_pid_file.map{|c| c[:name]} * ', '}"
    end
    
    dubl_pids = all_processes.each_with_object(Hash.new(0)){ |o, h| h[o[:pid_file]] += 1 }.select{|k,v| v>1}
    if dubl_pids.present?
      raise Eye::Dsl::Error, "dublicate pid_files: #{dubl_pids.inspect}"
    end

    dubl_names = all_processes.each_with_object(Hash.new(0)){ |o, h| h[o[:name]] += 1 }.select{|k,v| v>1}
    if dubl_names.present?
      raise Eye::Dsl::Error, "dublicate names: #{dubl_names.inspect}"
    end
  end

end