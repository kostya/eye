module Eye::Controller::Commands

  # Main method, answer for the client command
  def command(cmd, *args)
    debug "client command: #{cmd} #{args * ', '}"

    start_at = Time.now
    cmd = cmd.to_sym
    
    res = case cmd 
      when :start, :stop, :restart, :unmonitor, :monitor
        send_command(cmd, *args)
      when :delete
        exclusive{ send_command(cmd, *args) }
      when :signal
        signal(*args)
      when :break_chain
        break_chain(*args)
      when :load
        exclusive{ load(*args) }
      when :info
        info_string(*args)
      when :object_info
        info_data(*args)
      when :xinfo
        info_string_debug(*args)
      when :oinfo
        info_string_short
      when :quit
        quit
      when :check
        check(*args)
      when :explain
        explain(*args)
      when :match
        match(*args)
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
