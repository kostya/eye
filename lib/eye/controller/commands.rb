module Eye::Controller::Commands

  NOT_IMPORTANT_COMMANDS = [:info_data, :short_data, :debug_data, :history_data, :ping,
                            :logger_dev, :match, :explain, :check].freeze

  # Main method, answer for the client command
  def command(cmd, *args)
    opts = args.extract_options!
    msg = "command: #{cmd} #{args * ', '}"

    log_str = "=> #{msg}"
    NOT_IMPORTANT_COMMANDS.include?(cmd) ? debug(log_str) : info(log_str)

    start_at = Time.now
    cmd = cmd.to_sym

    res = case cmd

      # scheduled command
      when :start, :stop, :restart, :unmonitor, :monitor, :break_chain
        apply(args, command: cmd, signal: opts[:signal])
      when :delete
        exclusive { apply(args, command: cmd, signal: opts[:signal]) }
      when :signal, :user_command
        apply(args[1..-1], command: cmd, args: args[0...1], signal: opts[:signal])

      # inline command
      when :load
        exclusive { load(*args) }
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
        Eye::Logger.dev.to_s

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

    log_str = "<= #{msg} (#{Time.now - start_at}s)"
    NOT_IMPORTANT_COMMANDS.include?(cmd) ? debug(log_str) : info(log_str)

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
    # TODO: rewrite with signal
    exclusive do
      apply(%w[all], command: :break_chain)
      apply(%w[all], command: :stop, freeze: true)
    end

    # wait until all processes goes to unmonitored
    timeout ||= 100

    all_processes.pmap do |p|
      p.wait_for_condition(timeout, 0.3) do
        p.state_name == :unmonitored
      end
    end
  end

end
