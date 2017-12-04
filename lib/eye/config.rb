class Eye::Config

  attr_reader :settings, :applications

  def initialize(settings = {}, applications = {})
    @settings = settings
    @applications = applications
  end

  def merge(other_config)
    new_settings = {}
    Eye::Utils.deep_merge!(new_settings, @settings)
    Eye::Utils.deep_merge!(new_settings, other_config.settings)
    Eye::Config.new(new_settings, @applications.merge(other_config.applications))
  end

  def merge!(other_config)
    Eye::Utils.deep_merge!(@settings, other_config.settings)
    @applications.merge!(other_config.applications)
  end

  def to_h
    h = {}
    h[:settings] = @settings
    if Eye.respond_to?(:parsed_default_app)
      d = Eye.parsed_default_app
      h[:defaults] = d ? d.config : {}
    end
    h[:applications] = @applications
    h
  end

  # raise an error if config wrong
  def validate!(validate_apps = [])
    # Check blank pid_files
    no_pid_file = []
    each_process { |c| no_pid_file << c if c[:pid_file].blank? }
    if no_pid_file.any?
      raise Eye::Dsl::Error, "blank pid_file for: #{no_pid_file.map { |c| c[:name] } * ', '}"
    end

    # Check duplicates of the full pid_file

    dupl_pids = Hash.new(0)
    each_process do |o|
      ex_pid_file = Eye::System.normalized_file(o[:pid_file], o[:working_dir])
      dupl_pids[ex_pid_file] += 1
    end
    dupl_pids = dupl_pids.select { |_, v| v > 1 }

    if dupl_pids.any?
      raise Eye::Dsl::Error, "duplicate pid_files: #{dupl_pids.inspect}"
    end

    # Check duplicates of the full_name
    dupl_names = Hash.new(0)
    each_process do |o|
      full_name = "#{o[:application]}:#{o[:group]}:#{o[:name]}"
      dupl_names[full_name] += 1
    end
    dupl_names = dupl_names.select { |_, v| v > 1 }

    if dupl_names.any?
      raise Eye::Dsl::Error, "duplicate names: #{dupl_names.inspect}"
    end

    # validate processes with their own validate
    each_process do |process_cfg|
      Eye::Process.validate process_cfg, validate_apps.include?(process_cfg[:application])
    end

    # just to be sure ENV was not removed
    ENV[''] rescue raise Eye::Dsl::Error, "ENV is not a hash '#{ENV.inspect}'"
  end

  def transform!
    # transform syslog option
    each_process do |process|
      out = process[:stdout] && process[:stdout].start_with?(':syslog')
      err = process[:stderr] && process[:stderr].start_with?(':syslog')
      next unless err || out

      redir = err ? '2>&1' : ''
      process[:stdout] = nil if out
      process[:stderr] = nil if err

      escaped_start_command = process[:start_command].to_s.gsub(%{"}, %{\\"})

      names = [process[:application], process[:group] == '__default__' ? nil : process[:group], process[:name]].compact
      logger = "logger -t \"#{names.join(':')}\""

      process[:start_command] = %{sh -c "#{escaped_start_command} #{redir} | #{logger}"}
      process[:use_leaf_child] = true if process[:daemonize]
    end
  end

  def each_process(&block)
    applications.each do |_, app_cfg|
      (app_cfg[:groups] || {}).each do |_, gr_cfg|
        (gr_cfg[:processes] || {}).each_value(&block)
      end
    end
  end

  def application_names
    applications.keys
  end

  def delete_app(name)
    applications.delete(name)
  end

  def delete_group(name)
    applications.each do |_, app_cfg|
      (app_cfg[:groups] || {}).delete(name)
    end
  end

  def delete_process(name)
    applications.each do |_, app_cfg|
      (app_cfg[:groups] || {}).each do |_, gr_cfg|
        (gr_cfg[:processes] || {}).delete(name)
      end
    end
  end

end
