# encoding: utf-8

gem 'thor'
require 'thor'

class Eye::Cli < Thor
  autoload :Server,     'eye/cli/server'
  autoload :Commands,   'eye/cli/commands'
  autoload :Render,     'eye/cli/render'

  include Eye::Cli::Server
  include Eye::Cli::Commands
  include Eye::Cli::Render

  desc "info [MASK]", "processes info"
  method_option :json, :type => :boolean, :aliases => "-j"
  def info(mask = nil)
    res = cmd(:info_data, *Array(mask))
    if mask && res[:subtree] && res[:subtree].empty?
      error!("command :info, objects not found!")
    end

    if options[:json]
      require 'json'
      say JSON.dump(res)
    else
      say render_info(res)
      say
    end
  end

  desc "status NAME", "return exit status for process name 0-up, 3-unmonitored"
  def status(name)
    res = cmd(:info_data, *Array(name))
    es, msg = render_status(res)
    say(msg, :red) if msg && !msg.empty?
    exit(es)
  end

  desc "xinfo", "eye-deamon info (-c show current config)"
  method_option :config, :type => :boolean, :aliases => "-c"
  def xinfo
    res = cmd(:debug_data, :config => options[:config])
    say render_debug_info(res)
    say
  end

  desc "oinfo", "onelined info"
  def oinfo(mask = nil)
    res = cmd(:short_data, *Array(mask))
    say render_info(res)
    say
  end

  desc "history [MASK,...]", "processes history"
  def history(*masks)
    res = cmd(:history_data, *masks)
    if !masks.empty? && res && res.empty?
      error!("command :history, objects not found!")
    end
    say render_history(res)
    say
  end

  desc "load [CONF, ...]", "load config (run eye-daemon if not) (-f foreground load)"
  method_option :foreground, :type => :boolean, :aliases => "-f"
  def load(*configs)
    configs.map!{ |c| File.expand_path(c) } if !configs.empty?

    if options[:foreground]
      # in foreground we stop another server, and run just 1 current config version
      error!("foreground expected only one config") if configs.size > 1
      server_start_foreground(configs.first)

    elsif server_started?
      configs << Eye::Local.eyefile if Eye::Local.local_runner
      say_load_result cmd(:load, *configs)

    else
      server_start(configs)

    end
  end

  desc "quit", "eye-daemon quit"
  method_option :stop_all, :type => :boolean, :aliases => "-s"
  method_option :timeout, :type => :string, :aliases => "-t", :default => "600"
  def quit
    if options[:stop_all]
      Eye::Local.client_timeout = options[:timeout].to_i
      cmd(:stop_all, options[:timeout].to_i)
    end

    Eye::Local.client_timeout = Eye::Local.default_client_timeout
    res = _cmd(:quit)

    # if eye server got crazy, stop by force
    ensure_stop_previous_server if res != :corrupted_data

    # remove pid_file
    File.delete(Eye::Local.pid_path) if File.exists?(Eye::Local.pid_path)

    say "Quit ಠ╭╮ಠ", :yellow
  end

  [:start, :stop, :restart, :unmonitor, :monitor, :delete, :match].each do |_cmd|
    desc "#{_cmd} MASK[,...]", "#{_cmd} app,group or process"
    define_method(_cmd) do |*masks|
      send_command(_cmd, *masks)
    end
  end

  desc "signal SIG MASK[,...]", "send signal to app,group or process"
  def signal(sig, *masks)
    send_command(:signal, sig, *masks)
  end

  desc "break MASK[,...]", "break chain executing"
  def break(*masks)
    send_command(:break_chain, *masks)
  end

  desc "trace [MASK]", "tracing log(tail + grep) for app,group or process"
  def trace(mask = "")
    log_trace(mask)
  end

  map ["-v", "--version"] => :version
  desc "version", "version"
  def version
    say Eye::ABOUT
  end

  desc "check CONF", "check config file syntax"
  method_option :host, :type => :string, :aliases => "-h"
  method_option :verbose, :type => :boolean, :aliases => "-v"
  def check(conf)
    conf = File.expand_path(conf) if conf && !conf.empty?

    Eye::Local.host = options[:host] if options[:host]
    Eye::Dsl.verbose = options[:verbose]

    say_load_result Eye::Controller.new.check(conf), :syntax => true
  end

  desc "explain CONF", "explain config tree"
  method_option :host, :type => :string, :aliases => "-h"
  method_option :verbose, :type => :boolean, :aliases => "-v"
  def explain(conf)
    conf = File.expand_path(conf) if conf && !conf.empty?

    Eye::Local.host = options[:host] if options[:host]
    Eye::Dsl.verbose = options[:verbose]

    say_load_result Eye::Controller.new.explain(conf), :print_config => true, :syntax => true
  end

  desc "watch [MASK]", "interactive processes info"
  def watch(*args)
    error!("You should install watch utility") if `which watch`.empty?

    cmd = if `watch --version 2>&1`.chop > '0.2.0'
      "watch -n 1 --color #{$0} i #{args * ' '}"
    else
      "watch -n 1 #{$0} i #{args * ' '}"
    end

    pid = Process.spawn(cmd)
    Process.waitpid(pid)
  rescue Interrupt
  end

  desc "user_command CMD [MASK]", "execute user_command (dsl command)"
  def user_command(cmd, *args)
    send_command(:user_command, cmd, *args)
  end

private

  def error!(msg)
    say msg, :red
    exit 1
  end

  def print(msg, new_line = true)
    say msg if msg && !msg.empty?
    say if new_line
  end

  def log_trace(tag = '')
    log_file = cmd(:logger_dev)
    if log_file && File.exists?(log_file)
      Process.exec "tail -n 100 -f #{log_file} | grep '#{tag}'"
    else
      error! "log file not found #{log_file.inspect}"
    end
  end

  def self.exit_on_failure?
    true
  end
end
