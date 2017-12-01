class Eye::Application

  attr_reader :groups, :name, :config

  def initialize(name, config = {})
    @groups = Eye::Utils::AliveArray.new
    @name = name
    @config = config
    debug { 'created' }
  end

  def logger_tag
    full_name
  end

  def full_name
    @name
  end

  def add_group(group)
    @groups << group
  end

  def resort_groups
    @groups.sort! # used group method <=> to compare
  end

  def status_data(opts = {})
    h = { name: @name, type: :application, subtree: @groups.map { |gr| gr.status_data(opts) } }
    h[:debug] = debug_data if debug
    h
  end

  def status_data_short
    { name: @name, type: :application, subtree: @groups.map(&:status_data_short) }
  end

  def debug_data; end

  def send_call(call)
    info "call: #{call}"
    @groups.each { |group| group.send_call(call) }
  end

  def alive?
    true # emulate celluloid actor method
  end

  def sub_object?(obj)
    res = @groups.include?(obj)
    res ||= @groups.any? { |gr| gr.sub_object?(obj) }
    res
  end

  def processes
    out = []
    @groups.each { |gr| out += gr.processes.to_a }
    Eye::Utils::AliveArray.new(out)
  end

end
