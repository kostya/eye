class Eye::Dsl::Opts < Eye::Dsl::PureOpts

  STR_OPTIONS = [ :pid_file, :working_dir, :stdout, :stderr, :stdall, :stdin, :start_command,
    :stop_command, :restart_command, :uid, :gid ]
  create_options_methods(STR_OPTIONS, String)

  BOOL_OPTIONS = [ :daemonize, :keep_alive, :auto_start, :stop_on_delete, :clear_pid, :preserve_fds, :use_leaf_child, :clear_env ]
  create_options_methods(BOOL_OPTIONS, [TrueClass, FalseClass])

  INTERVAL_OPTIONS = [ :check_alive_period, :start_timeout, :restart_timeout, :stop_timeout, :start_grace,
    :restart_grace, :stop_grace, :children_update_period, :restore_in,
    :auto_update_pidfile_grace, :revert_fuckup_pidfile_grace ]
  create_options_methods(INTERVAL_OPTIONS, [Fixnum, Float])

  create_options_methods([:environment], Hash)
  create_options_methods([:umask], Fixnum)


  def initialize(name = nil, parent = nil)
    super(name, parent)

    @config[:application] = parent.name if parent.is_a?(Eye::Dsl::ApplicationOpts)
    @config[:group] = parent.name if parent.is_a?(Eye::Dsl::GroupOpts)

    # hack for full name
    @full_name = parent.full_name if @name == '__default__' && parent.respond_to?(:full_name)
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
    nac = Eye::Trigger.name_and_class(type.to_sym)
    raise Eye::Dsl::Error, "unknown trigger type #{type}" unless nac

    opts.merge!(:type => nac[:type])
    Eye::Trigger.validate!(opts)

    @config[:triggers] ||= {}
    @config[:triggers][nac[:name]] = opts
  end

  # clear checks from parent
  def nochecks(type)
    nac = Eye::Checker.name_and_class(type.to_sym)
    raise Eye::Dsl::Error, "unknown checker type #{type}" unless nac
    @config[:checks].try :delete, nac[:name]
  end

  # clear triggers from parent
  def notriggers(type)
    nac = Eye::Trigger.name_and_class(type.to_sym)
    raise Eye::Dsl::Error, "unknown trigger type #{type}" unless nac
    @config[:triggers].try :delete, nac[:name]
  end

  alias check checks
  alias nocheck nochecks
  alias trigger triggers
  alias notrigger notriggers

  def command(cmd, arg)
    @config[:user_commands] ||= {}

    if arg.is_a?(Array)
      validate_signals(arg)
    elsif arg.is_a?(String)
    else
      raise Eye::Dsl::Error, "unknown command #{cmd.inspect} type should be String or Array"
    end

    @config[:user_commands][cmd.to_sym] = arg
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

  def set_stop_command(cmd)
    raise Eye::Dsl::Error, "cannot use both stop_signals and stop_command" if @config[:stop_signals]
    super
  end

  def stop_signals(*args)
    raise Eye::Dsl::Error, "cannot use both stop_signals and stop_command" if @config[:stop_command]

    if args.count == 0
      return @config[:stop_signals]
    end

    signals = Array(args).flatten
    validate_signals(signals)
    @config[:stop_signals] = signals
  end

  def stop_signals=(s)
    stop_signals(s)
  end

  def set_environment(value)
    raise Eye::Dsl::Error, "environment should be a hash, but not #{value.inspect}" unless value.is_a?(Hash)
    @config[:environment] ||= {}
    @config[:environment].merge!(value)
  end

  alias dir working_dir
  alias env environment

  def set_stdall(value)
    super

    set_stdout value
    set_stderr value
  end

  def set_uid(value)
    raise Eye::Dsl::Error, ':uid not supported (use ruby >= 2.0)' unless Eye::Local.supported_setsid?
    super
  end

  def set_gid(value)
    raise Eye::Dsl::Error, ':gid not supported (use ruby >= 2.0)' unless Eye::Local.supported_setsid?
    super
  end

  def daemonize!
    set_daemonize true
  end

  def clear_bundler_env
    env('GEM_PATH' => nil, 'GEM_HOME' => nil, 'RUBYOPT' => nil, 'BUNDLE_BIN_PATH' => nil, 'BUNDLE_GEMFILE' => nil)
  end

  def scoped(&block)
    h = self.class.new(self.name, self)
    h.instance_eval(&block)
    Eye::Utils.deep_merge!(config, h.config, [:groups, :processes])
  end

  # execute part of config on particular server
  # array of strings
  # regexp
  # string
  def with_server(glob = nil, &block)
    on_server = true

    if glob.present?
      host = Eye::Local.host

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

  def load_env(filename = '~/.env', raise_when_no_file = true)
    fnames = [File.expand_path(filename, @config[:working_dir]),
      File.expand_path(filename)].uniq
    filenames = fnames.select { |f| File.exists?(f) }

    if filenames.size < 1
      unless raise_when_no_file
        warn "load_env not found file: '#{filenames.first}'"
        return
      else
        raise Eye::Dsl::Error, "load_env not found in #{fnames}"
      end
    end
    raise Eye::Dsl::Error, "load_env conflict filenames: #{filenames}" if filenames.size > 1

    content = File.read(filenames.first)
    info "load_env from '#{filenames.first}'"

    env_vars = content.split("\n")
    env_vars.each do |e|
      next unless e.include?('=')
      k, *v = e.split('=')
      env k => v.join('=')
    end
  end

private

  def validate_signals(signals = nil)
    return unless signals
    raise Eye::Dsl::Error, "signals should be Array" unless signals.is_a?(Array)
    s = signals.clone
    while s.present?
      sig = s.shift
      timeout = s.shift
      raise Eye::Dsl::Error, "signal should be String, Symbol, Fixnum, not #{sig.inspect}" if sig && ![String, Symbol, Fixnum].include?(sig.class)
      raise Eye::Dsl::Error, "signal sleep should be Numeric, not #{timeout.inspect}" if timeout && ![Fixnum, Float].include?(timeout.class)
    end
  end

end
