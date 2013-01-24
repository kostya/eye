class Eye::Dsl::Opts

  ALL_OPTIONS = [ :pid_file, :working_dir, :daemonize, :stdout, :stderr, :stdall,
    :keep_alive, :check_alive_period, :start_timeout, :restart_timeout, :stop_timeout, :start_grace,
    :restart_grace, :stop_grace, :control_pid, :childs_update_period,
    :auto_start, :start_command, :stop_command, :restart_command, :stop_signals, :stop_on_delete
  ]

  ALL_OPTIONS.each do |opt|
    define_method(opt) do |*args|
      if args.size == 0
        # getter
        @config[opt]
      else
        # setter
        arg = args[0]
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
    end

    define_method("#{opt}=") do |*args|
      send opt, *args
    end
  end

  attr_reader :name, :full_name

  def initialize(name = nil)
    @name = name.to_s
    @config = Eye::Utils::MHash.new
  end

  def checks(type, opts = {})
    type = type.to_sym
    raise Eye::Dsl::Error, "unknown checker type #{type}" unless Eye::Checker::TYPES[type]
    @config[:checks][type] = opts.merge(:type => type)
  end

  def triggers(type, opts = {})
    type = type.to_sym
    raise Eye::Dsl::Error, "unknown trigger type #{type}" unless Eye::Trigger::TYPES[type]
    @config[:triggers][type] = opts.merge(:type => type)
  end

  def nochecks(type)
    type = type.to_sym
    raise Eye::Dsl::Error, "unknown checker type #{type}" unless Eye::Checker::TYPES[type]
    @config[:nochecks][type] = 1
  end

  def notriggers(type)
    type = type.to_sym
    raise Eye::Dsl::Error, "unknown trigger type #{type}" unless Eye::Trigger::TYPES[type]
    @config[:notriggers][type] = 1
  end

  def environment(h = {})
    @config[:environment].merge!(h)
  end

  alias :env :environment

  def allow_options
    nil
  end

  def disallow_options
    []
  end

  def config
    @config.pure
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

    with_condition(on_server, &block)

    on_server
  end

  def with_condition(cond = true, &block)
    self.instance_eval(&block) if cond && block
  end

  def include(proc, *args)
    ie = if proc.is_a?(Symbol) || proc.is_a?(String)
      if args.present?
        lambda{|i| i.send(proc, i, *args) }
      else
        method(proc).to_proc
      end
    else
      proc
    end

    self.instance_eval(&ie)
  end

end