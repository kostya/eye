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

  def status_data(debug = false)
    {:name => "[#{@name}]", :subtree => @groups.map{|gr| gr.status_data(debug)}, :debug => debug ? debug_string : nil}
  end

  def debug_string    
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