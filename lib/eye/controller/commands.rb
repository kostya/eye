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
      when :xinfo
        info_string_debug(*args)
      when :oinfo
        info_string_short
      when :history
        history_string(*args)
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

      # object commands, for api
      when :raw_info
        info_data(*args)
      when :raw_history
        history_data(*args)

      else
        :unknown_command
    end

    GC.start
    info "client command: #{cmd} #{args * ', '} (#{Time.now - start_at}s)"

    res
  end

private

  def quit
    save_cache
    info 'exiting...'
    sleep 1
    Eye::System.send_signal($$) # soft terminate
    sleep 2
    Eye::System.send_signal($$, 9)
  end

end
