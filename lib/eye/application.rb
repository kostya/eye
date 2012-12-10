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

  def status_string
    res = "#{@name}\n"
    @groups.each{|gr| res << gr.status_string.map{|c| "  " + c}.join }
    res
  end

  def send_command(command)
    @groups.each do |group|
      group.send_command(command)
    end
  end

  def alive?
    true # emulate celluloid actor method
  end

end