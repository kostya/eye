require 'celluloid'

class Eye::Group
  include Celluloid

  autoload :Chain, 'eye/group/chain'

  include Eye::Logger::Helpers
  include Eye::Process::Scheduler
  include Eye::Group::Chain

  attr_reader :processes, :name, :hidden, :config

  def initialize(name, config)
    @name = name
    @config = config
    @logger = Eye::Logger.new(full_name)
    @processes = Eye::Utils::AliveArray.new
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

  # sort processes in name order
  def resort_processes
    @processes = @processes.sort_by(&:name)
  end

  def status_data(debug = false)
    plist = @processes.map{|p| p.status_data(debug) }

    h = { name: name, type: :group, subtree: plist }

    h.merge!(debug: debug_data) if debug

    # show current chain
    if current_scheduled_command
      h.update(current_command: current_scheduled_command) 

      if (chain_commands = scheduler_actions_list) && chain_commands.present?
        h.update(chain_commands: chain_commands) 
      end

      if @chain_processes_current && @chain_processes_count
        h.update(chain_progress: [@chain_processes_current, @chain_processes_count]) 
      end
    end

    h
  end

  def debug_data
    {:queue => scheduler_actions_list, :chain => chain_status}
  end

  def send_command(command, *args)
    info "send_command: #{command}"

    case command
      when :delete
        delete *args
      when :break_chain 
        break_chain *args
      else 
        schedule command, *args, "#{command} by user"
    end
  end

  def start
    chain_command :start
  end

  def stop
    async_schedule :stop
  end

  def restart
    chain_command :restart
  end

  def delete
    async_schedule :delete
    terminate
  end

  def monitor
    chain_command :monitor
  end

  def unmonitor
    async_schedule :unmonitor
  end

  def signal(sig)
    async_schedule :signal, sig
  end

  def break_chain
    info "break chain"
    scheduler.clear_pending_list
    @chain_breaker = true    
  end

  def clear
    @processes = Eye::Utils::AliveArray.new
  end

  def sub_object?(obj)
    @processes.include?(obj)
  end

private

  def async_schedule(command, *args)
    info "send to all processes #{command} #{args.present? ? args*',' : nil}"
    
    @processes.each do |process|
      process.send_command(command, *args)
    end    
  end

end
