module Eye::Dsl::Main
  attr_accessor :parsed_config, :parsed_options

  def application(name, &block)
    @parsed_config ||= {}
    opts = Eye::Dsl::ApplicationOpts.new
    opts.instance_eval(&block)
    @parsed_config[name.to_s] = opts.config if opts.config
  end

  alias :app :application 

  def load(glob = "")
    Dir[glob].each do |path|
      Kernel.load(path)
    end
  end

  def logger=(log_path)
    @parsed_options ||= {}
    @parsed_options[:logger] = log_path
  end
end
