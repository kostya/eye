class Eye::Dsl::ApplicationOpts < Eye::Dsl::Opts

  include Eye::Dsl::Chain

  def disallow_options
    [:pid_file, :start_command, :daemonize]
  end

  def not_seed_options
    [:groups]
  end

  def group(name, &block)
    Eye::Dsl.check_name(name)
    Eye::Dsl.debug "=> group #{name}"

    opts = Eye::Dsl::GroupOpts.new(name, self)
    opts.instance_eval(&block)

    if cfg = opts.config
      @config[:groups] ||= {}

      processes = cfg.delete(:processes) || {}
      @config[:groups][name.to_s] ||= {}
      @config[:groups][name.to_s].merge!(cfg)
      @config[:groups][name.to_s][:processes] ||= {}
      @config[:groups][name.to_s][:processes].merge!(processes)
    end

    Eye::Dsl.debug "<= group #{name}"
    opts
  end

  def process(name, &block)
    res = nil
    group('__default__'){ res = process(name.to_s, &block) }
    res
  end

  alias xgroup nop
  alias xprocess nop
end
