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
    Eye::Dsl.debug { "=> group #{name}" }

    opts = Eye::Dsl::GroupOpts.new(name, self)
    opts.instance_eval(&block)

    @config[:groups] ||= {}
    @config[:groups][name.to_s] ||= {}

    if cfg = opts.config
      Eye::Utils.deep_merge!(@config[:groups][name.to_s], cfg)
    end

    Eye::Dsl.debug { "<= group #{name}" }
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
