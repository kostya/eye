class Reactor
  include Celluloid

  def initialize(interval, filename)
    @interval = interval
    @filename = filename
    every(@interval) do
      info "check file #{@filename}"
      if cmd = read_file
        execute_command cmd
      end
    end
  end

  def read_file
    if File.exists?(@filename)
      cmd = File.read(@filename).chop
      File.delete(@filename) rescue nil
      cmd
    end
  end

  def execute_command(cmd)
    Eye::Control.command(cmd, 'all') if %w{restart start stop}.include?(cmd)
  end
end

class Saver < Eye::Trigger::Custom
  param :log_name, String, true

  def check(trans)
    tlogger.info "#{process.full_name} transition from #{trans.from_name} to #{trans.to_name}"
  end

  def tlogger
    @tlogger ||= Logger.new(log_name)
  end
end

def reactor
  Celluloid::Actor[:reactor]
end

# Extend config options, add enable_reactor
class Eye::Dsl::ConfigOpts
  def enable_reactor(*args)
    @config[:reactor] = args
  end

  def enable_saver(save_log)
    Eye.application '__default__' do
      trigger :saver, :log_name => save_log
    end
  end
end

# extend controller to execute method, and config loads
class Eye::Controller
  def set_opt_reactor(args)
    reactor.terminate if reactor
    Celluloid::Actor[:reactor] = Reactor.supervise(*args)
  end
end
