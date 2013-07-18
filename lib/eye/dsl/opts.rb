class Eye::Dsl::Opts < Eye::Dsl::PureOpts

  STR_OPTIONS = [ :pid_file, :working_dir, :stdout, :stderr, :stdall, :start_command,
    :stop_command, :restart_command, :uid, :gid ]
  create_options_methods(STR_OPTIONS, String)

  BOOL_OPTIONS = [ :daemonize, :keep_alive, :auto_start, :stop_on_delete, :clear_pid ]
  create_options_methods(BOOL_OPTIONS, [TrueClass, FalseClass])

  INTERVAL_OPTIONS = [ :check_alive_period, :start_timeout, :restart_timeout, :stop_timeout, :start_grace,
    :restart_grace, :stop_grace, :childs_update_period, :clear_pid ]
  create_options_methods(INTERVAL_OPTIONS, [Fixnum, Float])

  create_options_methods([:environment], Hash)
  create_options_methods([:stop_signals], Array)
  create_options_methods([:umask], Fixnum)


  def initialize(name = nil, parent = nil)
    super(name, parent)

    @config[:application] = parent.name if parent.is_a?(Eye::Dsl::ApplicationOpts)
    @config[:group] = parent.name if parent.is_a?(Eye::Dsl::GroupOpts)

    # hack for full name
    @full_name = parent.full_name if @name == '__default__'
  end

  def checks(type, opts = {})
    nac = Eye::Checker.name_and_class(type.to_sym)
    raise Eye::Dsl::Error, "unknown checker type #{type}" unless nac

    opts.merge!(:type => nac[:type])
    Eye::Checker.validate!(opts)

    @config[:checks] ||= {}
    @config[:checks][nac[:name]] = opts
  end

  def triggers(type, opts = {})
    type = type.to_sym
    raise Eye::Dsl::Error, "unknown trigger type #{type}" unless Eye::Trigger::TYPES[type]

    opts.merge!(:type => type)
    Eye::Trigger.validate!(opts)

    @config[:triggers] ||= {}
    @config[:triggers][type] = opts
  end

  # clear checks from parent
  def nochecks(type)
    nac = Eye::Checker.name_and_class(type.to_sym)
    raise Eye::Dsl::Error, "unknown checker type #{type}" unless nac
    @config[:checks].try :delete, nac[:name]
  end

  # clear triggers from parent
  def notriggers(type)
    type = type.to_sym
    raise Eye::Dsl::Error, "unknown trigger type #{type}" unless Eye::Trigger::TYPES[type]
    @config[:triggers].try :delete, type
  end

  def notify(contact, level = :warn)
    unless Eye::Process::Notify::LEVELS[level]
      raise Eye::Dsl::Error, "level should be in #{Eye::Process::Notify::LEVELS.keys}"
    end

    @config[:notify] ||= {}
    @config[:notify][contact.to_s] = level
  end

  def nonotify(contact)
    @config[:notify] ||= {}
    @config[:notify].delete(contact.to_s)
  end

  def set_environment(value)
    raise Eye::Dsl::Error, "environment should be a hash, but not #{value.inspect}" unless value.is_a?(Hash)
    @config[:environment] ||= {}
    @config[:environment].merge!(value)
  end

  alias env environment

  def set_stdall(value)
    super

    set_stdout value
    set_stderr value
  end

  def set_uid(value)
    raise Eye::Dsl::Error, ":uid not supported by ruby (needed 2.0)" unless Eye::Settings.supported_setsid?
    super
  end

  def set_gid(value)
    raise Eye::Dsl::Error, ":gid not supported by ruby (needed 2.0)" unless Eye::Settings.supported_setsid?
    super
  end

  def scoped(&block)
    h = self.class.new(self.name, self)
    h.instance_eval(&block)
    groups = h.config.delete :groups
    processes = h.config.delete :processes

    if groups.present?
      config[:groups] ||= {}
      config[:groups].merge!(groups)
    end

    if processes.present?
      config[:processes] ||= {}
      config[:processes].merge!(processes)
    end
  end

  # execute part of config on particular server
  # array of strings
  # regexp
  # string
  def with_server(glob = nil, &block)
    on_server = true

    if glob.present?
      host = Eye::System.host

      if glob.is_a?(Array)
        on_server = !!glob.any?{|elem| elem == host}
      elsif glob.is_a?(Regexp)
        on_server = !!host.match(glob)
      elsif glob.is_a?(String) || glob.is_a?(Symbol)
        on_server = (host == glob.to_s)
      end
    end

    scoped do
      with_condition(on_server, &block)
    end

    on_server
  end

end
