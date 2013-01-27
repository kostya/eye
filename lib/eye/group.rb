require 'celluloid'
require_relative 'utils/celluloid_chain'

class Eye::Group
  include Celluloid

  include Eye::Logger::Helpers

  # scheduler
  include Eye::Process::Scheduler

  attr_reader :processes, :name, :hidden, :config

  def initialize(name, config)
    @name = name
    @config = config
    @processes = []
    @logger = Eye::Logger.new([config[:application], name] * ':')
    @hidden = (name == '__default__')
    debug 'created'
  end

  def full_name
    @full_name ||= "#{@config[:application]}:#{@name}"
  end

  def update_config(cfg)
    @config = cfg
    @full_name = nil
  end

  def add_process(process)
    @processes << process
  end

  def status_data(debug = false)
    plist = @processes.sort_by(&:name).map{|p| p.status_data(debug) if p.alive? }.compact

    if @hidden
      plist
    else
      {:subtree => plist, :name => name, :debug => debug ? debug_data : nil}
    end
  end

  def debug_data
    {:queue => scheduler.names_list, :chain => chain_status}
  end

  def send_command(command)
    info "send_command: #{command}"

    if command == :delete
      delete
    else
      schedule command
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

  def delete
    async_all :delete
    terminate
  end

  def monitor
    async_all :monitor
  end

  def unmonitor
    async_all :unmonitor
  end

  def clear
    @processes = []
  end

  def sub_object?(obj)
    @processes.include?(obj)
  end

private  

  def async_all(command)
    info "send to all #{command}"
    
    @processes.each do |process|
      process.send_command(command) if process.alive?
    end    
  end

  def chain(type, command, grace = 0)
    info "start #{type} chain #{command} with #{grace}s"

    @processes.each do | process |
      # check alive, for prevent races, process can be dead here
      next unless process.alive?

      if type == :sync
        # sync command, with waiting
        process.send(command)
      else
        # async command
        process.send_command(command)
      end

      # wait next process
      sleep grace.to_f
    end
  end

  def chain_status
    if @config[:chain]
      [:start, :restart].map{|c| @config[:chain][c].try(:[], :grace) }
    end
  end

  def chain_command(command)
    if @config[:chain] && @config[:chain][command]
      type = @config[:chain][command][:type] || :async
      chain(type, command, @config[:chain][command][:grace] || 5)
    else
      async_all(command)
    end    
  end

end
