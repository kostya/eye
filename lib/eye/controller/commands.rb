module Eye::Controller::Commands

  # Main method, answer for the client command
  def command(cmd, *args)
    debug "client command: #{cmd} #{args * ', '}"

    start_at = Time.now
    cmd = cmd.to_sym
    
    res = case cmd 
      when :start, :stop, :restart, :delete, :unmonitor, :monitor
        send_command(cmd, *args)
      when :load
        load(*args)
      when :info
        status_string
      when :einfo
        status_string_debug
      when :quit
        quit
      when :syntax
        syntax(*args)
      when :explain
        explain(*args)
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
    delete
    sleep 1
    Eye::System.send_signal($$) # soft terminate
    sleep 2
    Eye::System.send_signal($$, 9)
  end

  def delete
    send_command(:delete)
  end

end
