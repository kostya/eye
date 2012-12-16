module Eye::Dsl::Main
  attr_accessor :parsed_config, :parsed_options, :parsed_filename

  def application(name, &block)
    @parsed_config ||= {}
    opts = Eye::Dsl::ApplicationOpts.new
    opts.instance_eval(&block)
    @parsed_config[name.to_s] = opts.config if opts.config
  end

  alias :app :application 

  def load(glob = "")
    return if glob.blank?

    require 'pathname'
    dirname = File.dirname(parsed_filename) rescue nil
    mask = Pathname.new(glob).expand_path(dirname).to_s
    Dir[mask].each do |path|
      Kernel.load(path)
    end
  end

  def logger=(log_path)
    @parsed_options ||= {}
    @parsed_options[:logger] = log_path
  end
end
