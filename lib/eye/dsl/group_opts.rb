class Eye::Dsl::GroupOpts < Eye::Dsl::Opts

  include Eye::Dsl::Chain

  def disallow_options
    [:pid_file, :start_command]
  end

  def process(name, &block)
    Eye::Dsl.debug "=> process #{name}"

    opts = Eye::Dsl::ProcessOpts.new(name, self)
    opts.instance_eval(&block)
    @config[:processes] ||= {}
    @config[:processes][name.to_s] = opts.config if opts.config

    Eye::Dsl.debug "<= process #{name}"
  end

  def xprocess(name, &block); end

  def application
    parent
  end
  alias :app :application

end
