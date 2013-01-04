require 'celluloid'
require_relative 'utils/celluloid_chain'

class Eye::ChildProcess
  include Celluloid

  # needs: kill_process
  include Eye::Process::Commands

  # easy config + defaults: prepare_config, c, []
  include Eye::Process::Config

  # conditional watchers: start_checkers
  include Eye::Process::Watchers

  # system methods: send_signal
  include Eye::Process::System

  # logger methods: info, ...
  include Eye::Logger::Helpers

  # self_status_data
  include Eye::Process::Data

  # manage notify methods
  include Eye::Process::Notify

  # scheduler
  include Eye::Process::Scheduler

  attr_reader :pid, :name, :config, :watchers

  def initialize(pid, config = {}, logger_prefix = nil)
    raise "Empty pid" unless pid

    @pid = pid
    @config = prepare_config(config)
    @name = '=child='

    @logger = Eye::Logger.new("#{logger_prefix} child:#{pid}")
    
    @watchers = {}

    debug "start monitoring CHILD config: #{@config.inspect}"

    start_checkers
  end

  def state
    :up
  end

  def stop
    kill_process
  end

  def restart
    stop
  end

  def monitor
  end

  def unmonitor
  end

  def remove
    remove_watchers
    self.terminate
  end

  def status_data(debug = false)
    self_status_data(debug)
  end

end