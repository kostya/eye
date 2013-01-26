class Eye::Dsl::ApplicationOpts < Eye::Dsl::Opts

  include Eye::Dsl::Chain

  def opts_name
    :application
  end

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
    #opts = Eye::Dsl::ProcessOpts.new(name, self)
    #opts.instance_eval(&block)
    #@config[:groups]['__default__'][:processes][name.to_s] = opts.config if opts.config
    
    group("__default__") do
      self.process(name.to_s, &block)
    end
  end

  def xgroup(name, &block); end
  def xprocess(name, &block); end
end
