class Eye::Application

  attr_reader :groups, :name

  include Eye::Logger::Helpers

  def initialize(name, config = {})
    @groups = []
    @name = name
    @logger = Eye::Logger.new(@name)
    @config = config
    debug "created"
  end

  def update_config(cfg)
    @config = cfg
  end

  def add_group(group)
    @groups << group
  end

  def status_data(debug = false)
    { :name => @name, 
      :subtree => @groups.map{|gr| gr.status_data(debug) if gr.alive? }.compact, 
      :debug => debug ? debug_data : nil,
    }
  end

  def debug_data
  end

  def send_command(command)
    @groups.each do |group|
      group.send_command(command) if group.alive?
    end
  end

  def alive?
    true # emulate celluloid actor method
  end

end