class Eye::Application

  attr_reader :groups, :name

  def initialize(name, config = {})
    @groups = Eye::Utils::AliveArray.new
    @name = name
    @config = config
    debug 'created'
  end

  def logger_tag
    full_name
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

  # sort processes in name order
  def resort_groups
    @groups = @groups.sort_by{|gr| gr.name == '__default__' ? 'zzzzz' : gr.name }
  end

  def status_data(debug = false)
    h = { name: @name, type: :application, subtree: @groups.map{|gr| gr.status_data(debug) }}
    h.merge!(debug: debug_data) if debug
    h
  end

  def status_data_short
    h = Hash.new 0
    @groups.each do |c|
      c.processes.each do |p|
        h[p.state] += 1
      end
    end
    str = h.sort_by{|a,b| a}.map{|k, v| "#{k}:#{v}" } * ', '
    { name: @name, type: :application, state: str}
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
    Eye::Utils::AliveArray.new(@groups.map{|gr| gr.processes.to_a }.flatten)
  end

end
