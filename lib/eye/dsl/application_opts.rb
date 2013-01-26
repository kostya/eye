class Eye::Dsl::ApplicationOpts < Eye::Dsl::Opts

  include Eye::Dsl::Chain

  def disallow_options
    [:pid_file]
  end

  def group(name, &block) 
    opts = Eye::Dsl::GroupOpts.new(name, self)
    opts.instance_eval(&block)    
    if cfg = opts.config
      processes = cfg.delete(:processes) || {}
      @config[:groups][name.to_s].merge!(cfg)
      @config[:groups][name.to_s][:processes].merge!(processes)      
    end
  end

  def process(name, &block)
    group("__default__"){ process(name.to_s, &block) }
  end

  def xgroup(name, &block); end
  def xprocess(name, &block); end
end
