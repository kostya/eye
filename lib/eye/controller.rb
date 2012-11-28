require 'active_support'
require 'active_support/time'
require 'active_support/core_ext'
require 'ostruct'

class Eye::Controller
  include Celluloid

  include Eye::Logger::Helpers

  attr_reader :applications

  def initialize(logger = nil)
    @logger = logger || Eye::Logger.new(STDOUT)
    @applications = []
  end

  def load(filename)
    if (cfg = open_config(filename))
      @current_config = cfg
      create_objects_by_config(cfg)
      true
    end
  end

  def status_string
    @applications.map{|app| app.status_string }.join("\n")
  end

  def send_command(command, obj_str = "")
    objs = find_objects(obj_str)
    return :nothing if objs.blank?

    res = "[#{objs.map{|obj| obj.name }.join(", ")}]"

    objs.each do |obj|
      obj.send_command(command)
      
      if command == :remove
        remove_object_from_tree(obj) 
        GC.start
      end
    end
    
    res
  end
  
  def command(cmd, *args)
    info "client command: #{cmd}, #{args.inspect}"
    cmd = cmd.to_sym
    
    case cmd 
      when :start, :stop, :restart, :remove, :unmonitor
        send_command(cmd, *args)
      when :load
        load(*args)
      when :status
        status_string
      when :quit
        quit
      when :ping
        :pong
      else
        :unknown_command
    end    
  end

  def quit
    info "Get quit command, exitting ..."
    remove
    sleep 1
    Eye::System.send_signal($$) # soft terminate
    sleep 2
    Eye::System.send_signal($$, 9)
  end

  def all_processes
    processes = []
    all_groups.each do |gr|
      processes += gr.processes
    end

    processes
  end

  def all_groups
    groups = []
    @applications.each do |app|
      groups += app.groups
    end

    groups
  end

  def remove
    send_command(:remove)
  end

private

  def open_config(filename)
    Eye::Dsl.load(nil, filename)
    
  rescue Eye::Dsl::Error => ex
    error "Error load config: #{ex.message}"
    nil
  end

  def create_objects_by_config(config)
    # should check existed objects,
    # and create only, and for old only update the config

    config.clone.each do |app_name, app_cfg|
      groups = app_cfg.delete(:groups)
      app = Eye::Application.new(app_name, app_cfg, @logger)
      @applications << app

      groups.each do |group_name, group_cfg|
        processes = group_cfg.delete(:processes)
        group = Eye::Group.new(group_name, group_cfg, @logger)
        app.add_group(group)

        processes.each do |process_name, process_cfg|
          process = Eye::Process.new(process_cfg, @logger)
          group.add_process(process)
          process.queue(:monitor)
        end
      end
    end
  end

  def remove_object_from_tree(obj)
    @applications.delete(obj)
    @applications.each{|app| app.groups.delete(obj) }
    @applications.each{|app| app.groups.each{|gr| gr.processes.delete(obj) }}
  end

  # find object to action, restart ... (app, group or process)
  # nil if not found
  def find_objects(str)
    return @applications if str.blank?

    res = []
    str = Regexp.escape(str).gsub('\*', ".*?")
    r = %r{\A#{str}\z}

    # find app
    res = @applications.select{|a| a.name =~ r }

    # find group
    @applications.each do |a|
      res += a.groups.select{|gr| gr.name =~ r }      
    end

    # find process
    @applications.each do |a|
      a.groups.each do |gr|
        res += gr.processes.select{|p| p.name =~ r }        
      end
    end

    res
  end

end
