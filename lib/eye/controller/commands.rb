module Eye::Controller::Commands

  # Main method, answer for the client command
  def command(cmd, *args)
    @mutex.synchronize{ safe_command(cmd, *args) }
  end

  def safe_command(cmd, *args)
    debug "client command: #{cmd} #{args * ', '}"

    start_at = Time.now
    cmd = cmd.to_sym
    
    res = case cmd 
      when :start, :stop, :restart, :remove, :unmonitor, :monitor
        send_command(cmd, *args)
      when :load
        load(*args)
      when :info
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

    GC.start
    info "client command: #{cmd} #{args * ', '} (#{Time.now - start_at}s)"

    res  
  end

private

  def quit
    info 'exiting...'
    remove
    sleep 1
    Eye::System.send_signal($$) # soft terminate
    sleep 2
    Eye::System.send_signal($$, 9)
  end

  def remove
    send_command(:remove)
  end

end