class Eye::Group
  include Celluloid

  include Eye::Logger::Helpers

  attr_reader :processes, :name, :hidden, :config

  def initialize(name, config, logger = nil)
    @name = name
    @config = config
    @processes = []
    prepare_logger(logger, name)    
    @hidden = (name == '__default__')
    @queue = Celluloid::Chain.new(current_actor)
    info "group add"
  end

  def queue(command)
    @queue.add_no_dup(command)
  end

  def add_process(process)
    @processes << process
  end

  def status_string
    res = []

    if @hidden
      @processes.each{|p| res += p.status_string }
    else
      res << "#{name}\n"
      @processes.each{|p| res += p.status_string.map{|c| "  " + c} }
    end     

    res
  end

  def send_command(command)
    info "get command: #{command}"

    if command == :remove
      remove
    else
      queue(command)
    end
  end

  def start
    chain_command(:start)
  end

  def stop
    async_all :stop
  end

  def restart
    chain_command(:restart)
  end

  def remove
    self.processes.each do |process|
      process.remove
    end

    @queue.terminate
    self.terminate
  end

  def unmonitor
    async_all :unmonitor
  end

private  

  def async_all(command)
    info "send to all #{command}"
    
    @processes.each do |process|
      process.send_command(command)
    end    
  end

  def sync_queue(command, grace = 0)
    info "start sync queue #{command} with #{grace}s"

    @processes.each do | process |
      # sync command, with waiting
      process.send(command)

      # wait next process
      sleep grace.to_f
    end
  end

  def async_queue(command, grace = 0)
    info "start async queue #{command} with #{grace}s"
    @processes.each do | process |
      # async command
      process.send_command(command)

      # wait next process
      sleep grace.to_f
    end
  end

  def chain_command(command)
    if @config[:chain] && @config[:chain][command]
      type = @config[:chain][command][:type] || :async

      if type == :sync
        sync_queue(command, @config[:chain][command][:grace] || 5)
      else
        async_queue(command, @config[:chain][command][:grace] || 5)
      end

    else
      async_all(command)
    end    
  end

end