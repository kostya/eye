class Eye::Dsl::GroupOpts < Eye::Dsl::Opts

  include Eye::Dsl::Chain

  def disallow_options
    [:pid_file, :start_command, :daemonize]
  end

  def not_seed_options
    [:processes, :chain]
  end

  def process(name, &block)
    Eye::Dsl.check_name(name)

    Eye::Dsl.debug { "=> process #{name}" }

    opts = Eye::Dsl::ProcessOpts.new(name, self)
    opts.instance_eval(&block)
    @config[:processes] ||= {}
    @config[:processes][name.to_s] ||= {}
    Eye::Utils.deep_merge!(@config[:processes][name.to_s], opts.config) if opts.config

    Eye::Dsl.debug { "<= process #{name}" }
    opts
  end

  alias xprocess nop
  alias application parent
  alias app application

end
