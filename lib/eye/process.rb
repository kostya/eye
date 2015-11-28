require 'celluloid'

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
  autoload :Children,         'eye/process/children'
  autoload :Trigger,          'eye/process/trigger'
  autoload :Notify,           'eye/process/notify'
  autoload :Scheduler,        'eye/process/scheduler'
  autoload :Validate,         'eye/process/validate'

  attr_accessor :pid, :parent_pid,
                :watchers, :config, :states_history,
                :children, :triggers, :name, :state_reason

  def initialize(config)
    raise 'you must supply a pid_file location' unless config[:pid_file]

    @config = prepare_config(config)

    @watchers = {}
    @children = {}
    @triggers = []
    @name = @config[:name]

    @states_history = Eye::Process::StatesHistory.new(100)
    @states_history << :unmonitored

    @state_call = {}

    debug { "creating with config: #{@config.inspect}" }

    add_triggers

    super() # for statemachine
  end

  # c(), self[]
  include Eye::Process::Config

  # full_name, status_data
  include Eye::Process::Data

  # commands:
  # start_process, stop_process, restart_process
  include Eye::Process::Commands

  # start, stop, restart, monitor, unmonit, delete
  include Eye::Process::Controller

  # add_watchers, remove_watchers:
  include Eye::Process::Watchers

  # check alive, crash methods:
  include Eye::Process::Monitor

  # system methods:
  include Eye::Process::System

  # manage child methods
  include Eye::Process::Children

  # manage triggers methods
  include Eye::Process::Trigger

  # manage notify methods
  include Eye::Process::Notify

  # scheduler
  include Eye::Process::Scheduler

  # validate
  extend Eye::Process::Validate

end

# include state_machine states
require_relative 'process/states'
