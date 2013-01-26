class Eye::Dsl::Opts < Eye::Dsl::PureOpts

  ALL_OPTIONS = [ :environment, :pid_file, :working_dir, :daemonize, :stdout, :stderr, :stdall,
    :keep_alive, :check_alive_period, :start_timeout, :restart_timeout, :stop_timeout, :start_grace,
    :restart_grace, :stop_grace, :control_pid, :childs_update_period,
    :auto_start, :start_command, :stop_command, :restart_command, :stop_signals, :stop_on_delete
  ]

  create_options_methods(ALL_OPTIONS)

  def initialize(name = nil, parent = nil)
    super(name, parent)

    # ensure delete subobjects which can appears from parent config
    @config.delete :groups
    @config.delete :processes

    @config[:application] = parent.name if parent.is_a?(Eye::Dsl::ApplicationOpts)
    @config[:group] = parent.name if parent.is_a?(Eye::Dsl::GroupOpts)
  end

  def checks(type, opts = {})
    type = type.to_sym
    raise Eye::Dsl::Error, "unknown checker type #{type}" unless Eye::Checker::TYPES[type]
    @config[:checks] ||= {}
    @config[:checks][type] = opts.merge(:type => type)
  end

  def triggers(type, opts = {})
    type = type.to_sym
    raise Eye::Dsl::Error, "unknown trigger type #{type}" unless Eye::Trigger::TYPES[type]
    @config[:triggers] ||= {}
    @config[:triggers][type] = opts.merge(:type => type)
  end

  def nochecks(type) #REF
    type = type.to_sym
    raise Eye::Dsl::Error, "unknown checker type #{type}" unless Eye::Checker::TYPES[type]
    @config[:nochecks] ||= {}
    @config[:nochecks][type] = 1
  end

  def notriggers(type) #REF
    type = type.to_sym
    raise Eye::Dsl::Error, "unknown trigger type #{type}" unless Eye::Trigger::TYPES[type]
    @config[:notriggers] ||= {}
    @config[:notriggers][type] = 1
  end

  def set_environment(value)
    @config[:environment] ||= {}
    @config[:environment].merge!(value)
  end

  alias :env :environment

  def set_stdall(value)
    super

    set_stdout value
    set_stderr value
  end

end