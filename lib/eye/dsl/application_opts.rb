class Eye::Dsl::ApplicationOpts < Eye::Dsl::Opts

  include Eye::Dsl::Chain

  def disallow_options
    [:pid_file]
  end

  def group(name, &block) 
    opts = Eye::Dsl::GroupOpts.new(name)
    opts.instance_eval(&block)
    @config[:groups][name.to_s] = opts.config if opts.config
  end

  def process(name, &block)
    opts = Eye::Dsl::ProcessOpts.new(name)
    opts.instance_eval(&block)
    @config[:groups]['__default__'][:processes][name.to_s] = opts.config if opts.config
  end

  def xgroup(name, &block); end
  def xprocess(name, &block); end
end
