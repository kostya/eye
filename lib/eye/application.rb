class Eye::Application

  attr_reader :groups, :name

  include Eye::Logger::Helpers

  def initialize(name, config = {}, logger = nil)
    @groups = []
    @name = name
    prepare_logger(logger, @name)
    @config = config
    info "create app"
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

end