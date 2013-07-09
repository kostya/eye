class Eye::Config

  attr_reader :settings, :applications

  def initialize(settings = {}, applications = {})
    @settings = settings
    @applications = applications
  end

  def merge(other_config)
    Eye::Config.new(@settings.merge(other_config.settings), @applications.merge(other_config.applications))
  end

  def merge!(other_config)
    @settings.merge!(other_config.settings)
    @applications.merge!(other_config.applications)
  end

  def to_h
    {:settings => @settings, :applications => @applications}
  end

  # raise an error if config wrong
  def validate!
    all_processes = processes

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

    # validate processes with their own validate
    all_processes.each do |process_cfg|
      Eye::Process.validate process_cfg
    end
  end

  def processes
    applications.values.map{|e| (e[:groups] || {}).values.map{|c| (c[:processes] || {}).values} }.flatten
  end

  def application_names
    applications.keys
  end

  def delete_app(name)
    applications.delete(name)
  end

  def delete_group(name)
    applications.each do |app_name, app_cfg|
      app_cfg[:groups].delete(name)
    end
  end

  def delete_process(name)
    applications.each do |app_name, app_cfg|
      app_cfg[:groups].each do |gr_name, gr_cfg|
        gr_cfg[:processes].delete(name)
      end
    end
  end

end