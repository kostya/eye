class Eye::Application

  attr_reader :groups, :name

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

  # sort processes in name order
  def resort_groups
    @groups = @groups.sort { |a, b| a.hidden ? 1 : (b.hidden ? -1 : (a.name <=> b.name)) }
  end

  def status_data(debug = false)
    h = { name: @name, type: :application, subtree: @groups.map{|gr| gr.status_data(debug) }}
    h.merge!(debug: debug_data) if debug
    h
  end

  def status_data_short
    h = Hash.new
    @groups.each do |c|
      c.processes.each do |p|
        h[p.state] ||= 0
        h[p.state] += 1
      end
    end
    { name: @name, type: :application, states: h}
  end

  def debug_data
  end

  def send_command(command, *args)
    info "send_command #{command}"

    @groups.each do |group|
      group.send_command(command, *args)
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

  def processes
    out = []
    @groups.each{|gr| out += gr.processes.to_a }
    Eye::Utils::AliveArray.new(out)
  end

end
