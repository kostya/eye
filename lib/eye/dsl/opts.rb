class Eye::Dsl::Opts

  ALL_OPTIONS = [ :pid_file, :environment, :working_dir, :daemonize, :stdout, :stderr, :stdall,
    :keep_alive, :check_alive_period, :start_timeout, :restart_timeout, :stop_timeout, :start_grace,
    :restart_grace, :stop_grace, :clear_pid_file, :childs_update_period,
    :auto_start, :start_command, :stop_command, :restart_command
  ]

  ALL_OPTIONS.each do |opt|
    define_method(opt) do |arg|
      @config ||= {}
      key = opt.to_sym

      if disallow_options.include?(key) || (allow_options && !allow_options.include?(key))
        raise Eye::Dsl::Error, "disallow option #{key} for #{self.class.inspect}"
      end

      case key 
      when :stdall
        @config[:stdout] = @config[:stderr] = arg
      else
        @config[ key ] = arg
      end
    end

    define_method("#{opt}=") do |arg|
      send opt, arg
    end
  end

  def initialize
    @config = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
  end

  def checks(type, opts = {})
    type = type.to_sym
    raise Eye::Dsl::Error, "unknown checker type #{type}" unless Eye::Checker::TYPES.include?(type)
    @config[:checks][type] = opts.merge(:type => type)
  end

  def triggers(type, opts = {})
    type = type.to_sym
    raise Eye::Dsl::Error, "unknown trigger type #{type}" unless Eye::Trigger::TYPES.include?(type)
    @config[:triggers][type] = opts.merge(:type => type)
  end

  def allow_options
    nil
  end

  def disallow_options
    []
  end

  # purefy config, from default value {}
  def config
    h = {}
    @config.each do |k,v|
      h[k] = v
    end
    h
  end

end