module Eye::Dsl::Main
  attr_accessor :parsed_config, :parsed_options, :parsed_filename

  def application(name, &block)
    Eye::Dsl.debug "=> app: #{name}"
    @parsed_config ||= {}
    opts = Eye::Dsl::ApplicationOpts.new(name)
    opts.instance_eval(&block)
    @parsed_config[name.to_s] = opts.config if opts.config
    Eye::Dsl.debug "<= app: #{name}"
  end

  alias :app :application 

  def load(glob = '')
    return if glob.blank?

    Eye::Dsl::Opts.with_parsed_file(glob) do |mask|
      Dir[mask].each do |path|
        Eye::Dsl.debug "=> load #{path}"
        res = Kernel.load(path)
        Eye.info "load: subload #{path} (#{res})"
        Eye::Dsl.debug "<= load #{path}"
      end
    end
  end

  def logger=(log_path)
    @parsed_options ||= {}
    @parsed_options[:logger] = log_path
  end
  
  def logger_level=(log_level)
    @parsed_options ||= {}
    @parsed_options[:logger_level] = log_level
  end
end
