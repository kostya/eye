require 'celluloid'

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

  attr_reader :pid, :name, :full_name, :config, :watchers

  def initialize(pid, config = {}, logger_prefix = nil)
    raise 'Empty pid' unless pid

    @pid = pid
    @config = prepare_config(config)
    @name = "child-#{pid}"
    @full_name = [logger_prefix, @name] * ':'

    @logger = Eye::Logger.new(@full_name)

    @watchers = {}

    debug "start monitoring CHILD config: #{@config.inspect}"

    start_checkers
  end

  def state
    :up
  end

  def up?
    state == :up
  end

  def send_command(command, *args)
    schedule command, *args, Eye::Reason::User.new(command)
  end

  def start
  end

  def stop
    kill_process
  end

  def restart
    if self[:restart_command]
      execute_restart_command
    else
      stop
    end
  end

  def monitor
  end

  def unmonitor
  end

  def delete
  end

  def destroy
    remove_watchers
    terminate
  end

  def signal(sig)
    if self.pid
      res = send_signal(sig)
      info "send signal #{sig} to #{self.pid} = #{res}"
    end
  end

  def status_data(debug = false)
    self_status_data(debug)
  end

end