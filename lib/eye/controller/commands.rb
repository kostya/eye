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
      when :quit
        quit
      when :stop_all
        stop_all(*args)
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
      when :info_data
        info_data(*args)
      when :short_data
        short_data(*args)
      when :debug_data
        debug_data(*args)
      when :history_data
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

  # stop all processes and wait
  def stop_all(timeout = nil)
    exclusive do
      send_command :break_chain, 'all'
      send_command :stop, 'all'

      # wait until all processes goes to unmonitored
      timeout ||= 100

      all_processes.pmap do |p|
        p.wait_for_condition(timeout, 0.3) do
          p.state_name == :unmonitored
        end
      end
    end
  end

end
