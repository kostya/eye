class Eye::Dsl::ApplicationOpts < Eye::Dsl::Opts

  include Eye::Dsl::Chain

  def disallow_options
    [:pid_file, :start_command]
  end

  def not_seed_options
    [:groups]
  end

  def group(name, &block) 
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
  end

  def process(name, &block)
    group("__default__"){ process(name.to_s, &block) }
  end

  def xgroup(name, &block); end
  def xprocess(name, &block); end
end
