module Eye::Controller::Commands

  # Main method, as anwer for client command
  def command(cmd, *args)
    # it is import that command processed one by one
    @mutex.synchronize do
      safe_command(cmd, *args)
    end
  end

  def safe_command(cmd, *args)
    info "client command: #{cmd} #{args * ', '}"
    start_at = Time.now
    cmd = cmd.to_sym
    
    res = case cmd 
      when :start, :stop, :restart, :remove, :unmonitor
        send_command(cmd, *args)
      when :load
        load(*args)
      when :status
        status_string
      when :debug
        status_string_debug
      when :quit
        quit
      when :syntax
        syntax(*args)
      when :ping
        :pong
      when :logger_dev
        Eye::Logger.dev
      else
        :unknown_command
    end   

    debug "client command: #{cmd} #{args * ', '} end #{Time.now - start_at}"

    res  
  end

  def send_command(command, obj_str = "")
    objs = find_objects(obj_str)
    return :nothing if objs.blank?

    res = "[#{objs.map{|obj| obj.name }.join(", ")}]"

    objs.each do |obj|
      next unless obj.alive?
      
      obj.send_command(command)
      
      if command == :remove
        remove_object_from_tree(obj) 
        GC.start
      end
    end
    
    res
  end

  def quit
    info "exiting..."
    remove
    sleep 1
    Eye::System.send_signal($$) # soft terminate
    sleep 2
    Eye::System.send_signal($$, 9)
  end

  def remove
    send_command(:remove)
  end

private

  def remove_object_from_tree(obj)
    @applications.delete(obj)
    @applications.each{|app| app.groups.delete(obj) }
    @applications.each{|app| app.groups.each{|gr| gr.processes.delete(obj) }}
  end

  # find object to action, restart ... (app, group or process)
  # nil if not found
  def find_objects(str)
    return nil if str.blank?
    return @applications if str.strip == 'all'

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