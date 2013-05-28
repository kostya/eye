module Eye::Controller::Load

  def check(filename = '')
    catch_load_error(filename) do
      parse_config(filename)
    end
  end

  def explain(filename)
    catch_load_error(filename) do
      parse_set_of_configs(filename).to_h
    end
  end

  # filename is a path, or folder, or mask
  def load(filename = '')
    catch_load_error(filename) do
      _load(filename)
      set_proc_line
    end
  end

private

  # regexp for clean backtrace to show for user
  BT_REGX = %r[/lib/eye/|lib/celluloid|internal:prelude|logger.rb:|active_support/core_ext|shellwords.rb].freeze

  def catch_load_error(filename, &block)
    {:error => false, :config => yield }

  rescue Eye::Dsl::Error, Exception, NoMethodError => ex
    error "load: config error <#{filename}>: #{ex.message}"

    # filter backtrace for user output
    bt = (ex.backtrace || [])
    bt = bt.reject{|line| line.to_s =~ BT_REGX }
    error bt.join("\n")

    res = {:error => true, :message => ex.message}
    res.merge!(:backtrace => bt) if bt.present?
    res
  end

  # return: result, config
  def parse_config(filename = '', &block)
    raise Eye::Dsl::Error, "config file '#{filename}' not found!" unless File.exists?(filename)

    cfg = Eye::Dsl.parse(nil, filename)
    @current_config.merge(cfg).validate! # just validate summary config here
    cfg
  end

  def parse_set_of_configs(filename)
    mask = if File.directory?(filename)
      File.join filename, '{*.eye}'
    else
      filename
    end

    debug "load: globbing mask #{mask}"
    configs = []

    Dir[mask].each do |config_path|
      info "load: config #{config_path}"
      configs << parse_config(config_path)
    end

    raise Eye::Dsl::Error, "config file '#{mask}' not found!" if configs.blank?

    @loaded_config = Eye::Config.new
    configs.each { |cfg| @loaded_config.merge!(cfg) }

    new_cfg = @current_config.merge(@loaded_config)
    new_cfg.validate!
    new_cfg
  end

  def _load(filename)
    info "load: #{filename} in #{Eye::VERSION}"
    new_cfg = parse_set_of_configs(filename)
    
    load_config(new_cfg, @loaded_config.application_names)
    @loaded_config = nil
  end

  def load_config(new_config, changed_apps = [])
    load_options(new_config.settings)
    create_objects(new_config.applications, changed_apps)
    @current_config = new_config
  end

  # load global config options
  def load_options(opts)
    return if opts.blank?

    if opts[:logger]
      # do not apply logger, if in stdout state
      if !%w{stdout stderr}.include?(Eye::Logger.dev)
        if opts[:logger].blank?
          Eye::Logger.link_logger(nil)
        else
          Eye::Logger.link_logger(opts[:logger])
        end
      end
      
      Eye::Logger.log_level = opts[:logger_level] if opts[:logger_level]
    end
  end

  # create objects as diff, from configs
  def create_objects(apps_config, changed_apps = [])
    debug 'create objects'
    apps_config.each do |app_name, app_cfg|
      update_or_create_application(app_name, app_cfg.clone) if changed_apps.include?(app_name)
    end

    # sorting applications
    @applications.sort_by!(&:name)
  end

  def update_or_create_application(app_name, app_config)
    @old_groups = {}
    @old_processes = {}

    app = @applications.detect{|c| c.name == app_name}

    if app
      app.groups.each do |group|
        @old_groups[group.name] = group
        group.processes.each do |proc|
          @old_processes[proc.name] = proc
        end
      end

      @applications.delete(app)

      debug "update app #{app_name}"
    else
      debug "create app #{app_name}"
    end

    app = Eye::Application.new(app_name, app_config)
    @applications << app
    @added_groups, @added_processes = [], []

    new_groups = app_config.delete(:groups) || {}
    new_groups.each do |group_name, group_cfg|
      group = update_or_create_group(group_name, group_cfg.clone)
      app.add_group(group)
      group.resort_processes
    end

    # now, need to clear @old_groups, and @old_processes    
    @old_groups.each{|_, group| group.clear; group.send_command(:delete) }
    @old_processes.each{|_, process| process.send_command(:delete) if process.alive? }

    # schedule monitoring for new groups, processes
    added_fully_groups = []
    @added_groups.each do |group|
      if group.processes.size > 0 && (group.processes.pure - @added_processes).size == 0
        added_fully_groups << group
        @added_processes -= group.processes.pure 
      end
    end

    added_fully_groups.each{|group| group.send_command :monitor }
    @added_processes.each{|process| process.send_command :monitor }

    # remove links to prevent memory leaks
    @old_groups = nil
    @old_processes = nil
    @added_groups = nil
    @added_processes = nil

    app.resort_groups

    app
  end

  def update_or_create_group(group_name, group_config)
    group = if @old_groups[group_name]
      debug "update group #{group_name}"
      group = @old_groups.delete(group_name)
      group.schedule :update_config, group_config, 'load config'
      group.clear
      group
    else
      debug "create group #{group_name}"
      gr = Eye::Group.new(group_name, group_config)
      @added_groups << gr
      gr
    end

    processes = group_config.delete(:processes) || {}
    processes.each do |process_name, process_cfg|
      process = update_or_create_process(process_name, process_cfg.clone)
      group.add_process(process)
    end

    group
  end

  def update_or_create_process(process_name, process_cfg)
    if @old_processes[process_name]
      debug "update process #{process_name}"
      process = @old_processes.delete(process_name)
      process.schedule :update_config, process_cfg, 'load config'
      process      
    else
      debug "create process #{process_name}"
      process = Eye::Process.new(process_cfg)
      @added_processes << process
      process
    end
  end

end