class Eye::Dsl::Opts

  ALL_OPTIONS = [ :pid_file, :working_dir, :daemonize, :stdout, :stderr, :stdall,
    :keep_alive, :check_alive_period, :start_timeout, :restart_timeout, :stop_timeout, :start_grace,
    :restart_grace, :stop_grace, :control_pid, :childs_update_period,
    :auto_start, :start_command, :stop_command, :restart_command, :stop_signals, :stop_on_delete
  ]

  ALL_OPTIONS.each do |opt|
    define_method(opt) do |*args|
      if args.blank?
        # getter
        @config[opt]
      else
        # setter
        key = opt.to_sym

        if disallow_options.include?(key) || (allow_options && !allow_options.include?(key))
          raise Eye::Dsl::Error, "disallow option #{key} for #{self.class.inspect}"
        end

        case key 
        when :stdall #REF
          @config[:stdout] = @config[:stderr] = args[0]
        else
          @config[ key ] = args[0]
        end
      end
    end

    define_method("#{opt}=") do |*args|
      send opt, *args
    end
  end

  attr_reader :name, :full_name, :parent

  def initialize(name = nil, parent = nil)
    @name = name.to_s

    if parent
      @parent = parent
      @config = parent.deep_cloned_config

      # get only options, without subobjects
      @config.delete :groups
      @config.delete :processes

      @config[:application] = parent.name if parent.is_a?(Eye::Dsl::ApplicationOpts)
      @config[:group] = parent.name if parent.is_a?(Eye::Dsl::GroupOpts)
    else
      @config = Eye::Utils::MHash.new
    end

    @config[:name] = @name if @name.present?
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

  def nochecks(type) #REF
    type = type.to_sym
    raise Eye::Dsl::Error, "unknown checker type #{type}" unless Eye::Checker::TYPES[type]
    @config[:nochecks][type] = 1
  end

  def notriggers(type) #REF
    type = type.to_sym
    raise Eye::Dsl::Error, "unknown trigger type #{type}" unless Eye::Trigger::TYPES[type]
    @config[:notriggers][type] = 1
  end

  def environment(*args)
    @config[:environment] = Hash.new unless @config.has_key?(:environment)
    
    if args.blank?
      # getter
      @config[:environment]
    else
      # setter
      @config[:environment].merge!(*args)
    end
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

  def deep_cloned_config
    @config.deep_clone
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