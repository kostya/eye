require 'celluloid'
require_relative 'celluloid_chain'

class Eye::Process
  include Celluloid
  
  autoload :Config,           'eye/process/config'
  autoload :Commands,         'eye/process/commands'
  autoload :Data,             'eye/process/data'
  autoload :Watchers,         'eye/process/watchers'
  autoload :Monitor,          'eye/process/monitor'
  autoload :System,           'eye/process/system'
  autoload :Controller,       'eye/process/controller'
  autoload :StatesHistory,    'eye/process/states_history'
  autoload :Child,            'eye/process/child'
  autoload :Logger,           'eye/process/logger'
  autoload :Trigger,          'eye/process/trigger'

  attr_accessor :pid, :logger, :watchers, :config, :states_history, 
                :state_reason, :childs, :triggers, :flapping, :name
  
  def initialize(config, logger = nil)
    raise "pid file should be" unless config[:pid_file]

    @config = prepare_config(config)

    @logger = logger || Eye::Logger.new(nil)
    @logger.tag = full_name

    @watchers = {}
    @childs = {}
    @triggers = []
    @flapping = false
    @name = @config[:name]

    @queue = Celluloid::Chain.new(current_actor)

    @states_history = Eye::Process::StatesHistory.new(1000)
    @states_history << :unmonitored

    debug "start monitoring config: #{@config.inspect}"

    add_triggers

    super()
  end

  # c()
  # self[]  
  include Eye::Process::Config
  
  # states:
  # statemachine
  # include Eye::Process::States
  
  # data:
  # pid
  # state
  # queue
  # dsl options
  include Eye::Process::Data
  
  # commands:
  # start_process, stop_process, restart_process
  # sleep
  # unsleep
  include Eye::Process::Commands

  # start, stop, restart
  include Eye::Process::Controller
  
  # checks:
  # cpu
  # memory
  # http
  # user defined
  include Eye::Process::Watchers
  
  # monitor:
  # method monitor! for start actor (Eye::Process.new(config).monitor!)
  include Eye::Process::Monitor

  # system methods:
  include Eye::Process::System

  # child methods
  include Eye::Process::Child

  # logger methods
  include Eye::Process::Logger

  # trigger
  include Eye::Process::Trigger
    
end

require_relative 'process/states'