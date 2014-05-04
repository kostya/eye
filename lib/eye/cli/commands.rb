module Eye::Cli::Commands
private

  def client
    @client ||= Eye::Client.new(Eye::Local.socket_path)
  end

  def _cmd(cmd, *args)
    client.command(cmd, *args)
  rescue Errno::ECONNREFUSED, Errno::ENOENT
    :not_started
  end

  def cmd(cmd, *args)
    res = _cmd(cmd, *args)

    if res == :not_started
      error! "socket(#{Eye::Local.socket_path}) not found, did you run `eye load`?"
    elsif res == :timeouted
      error! 'eye timed out without responding...'
    end

    res
  end

  def say_load_result(res = {}, opts = {})
    error!(res) unless res.is_a?(Hash)
    say_filename = (res.size > 1)
    error = false
    res.each do |filename, _res|
      say "#{filename}: ", nil, true if say_filename
      show_load_message(_res, opts)
      error = true if _res[:error]
    end

    exit(1) if error
  end

  def show_load_message(res, opts = {})
    if res[:error]
      say res[:message], :red
      res[:backtrace].to_a.each{|line| say line, :red }
    else
      if opts[:syntax]
        say 'Config ok!', :green if !res[:empty]
      else
        say 'Config loaded!', :green if !res[:empty]
      end

      if opts[:print_config]
        require 'pp'
        PP.pp res[:config], STDOUT, 150
      end
    end
  end

  def send_command(_cmd, *args)
    res = cmd(_cmd, *args)
    if res == :unknown_command
      error! "unknown command :#{_cmd}"
    elsif res == :corrupted_data
      error! 'something crazy wrong, check eye logs!'
    elsif res.is_a?(Hash)
      if res[:error]
        error! "Error: #{res[:error]}"
      elsif res = res[:result]
        if res == []
          error! "command :#{_cmd}, objects not found!"
        else
          say "command :#{_cmd} sent to [#{res * ", "}]"
        end
      end
    else
      error! "unknown result #{res.inspect}"
    end
  end

end
