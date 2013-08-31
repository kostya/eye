module Eye::Controller::Commands

  # Main method, answer for the client command
  def command(cmd, *args)
    debug "client command: #{cmd} #{args * ', '}"

    start_at = Time.now
    cmd = cmd.to_sym

    res = case cmd
      when :start, :stop, :restart, :unmonitor, :monitor, :break_chain
        send_command(cmd, *args)
      when :delete
        exclusive{ send_command(cmd, *args) }
      when :signal
        signal(*args)
      when :load
        load(*args)
      when :info
        info_string(*args)
      when :xinfo
        info_string_debug(*args)
      when :oinfo
        info_string_short(*args)
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
    info 'Quit!'
    Eye::System.send_signal($$, :TERM)
    sleep 1
    Eye::System.send_signal($$, :KILL)
  end

end
