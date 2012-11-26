module Eye::Dsl::Main
  attr_accessor :temp_config, :current_config

  def application(name, &block)
    @temp_config ||= {}
    opts = Eye::Dsl::ApplicationOpts.new
    opts.instance_eval(&block)
    @temp_config[name.to_s] = opts.config if opts.config
  end

  alias :app :application 

  def load(glob = "")
    Dir[glob].each do |path|
      Kernel.load(path)
    end
  end
end
