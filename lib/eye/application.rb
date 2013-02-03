class Eye::Application

  attr_reader :groups, :name

  include Eye::Logger::Helpers

  def initialize(name, config = {})
    @groups = []
    @name = name
    @logger = Eye::Logger.new(full_name)
    @config = config
    debug 'created'
  end

  def full_name
    @name
  end

  def update_config(cfg)
    @config = cfg
  end

  def add_group(group)
    @groups << group
  end

  def status_data(debug = false)
    h = { name: @name, 
      subtree: @groups.map{|gr| gr.status_data(debug) if gr.alive? }.compact }
    h.merge!(debug: debug_data) if debug
    h
  end

  def debug_data
  end

  def send_command(command)
    debug "send_command #{command}"
    
    @groups.each do |group|
      group.send_command(command) if group.alive?
    end
  end

  def alive?
    true # emulate celluloid actor method
  end

  def sub_object?(obj)
    res = @groups.include?(obj)
    res = @groups.any?{|gr| gr.sub_object?(obj)} if !res
    res
  end

end