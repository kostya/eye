module Eye::Cli::Render

private

  def render_status(data)
    return [1, "unexpected server response #{data.inspect}"] unless data.is_a?(Hash)
    data = data[:subtree]
    return [1, "match #{data.size} objects (#{data.map { |d| d[:name] }}), but expected only 1 process"] if data.size != 1
    process = data[0]
    return [1, "unknown status for :#{process[:type]}=#{process[:name]}"] unless process[:type] == :process

    state = process[:state].to_sym
    return [0, ''] if state == :up
    return [3, ''] if state == :unmonitored

    [4, "process #{process[:name]} state :#{state}"]
  end

  def render_info(data)
    error!("unexpected server response #{data.inspect}") unless data.is_a?(Hash)

    make_str data
  end

  def make_str(data, level = -1)
    return nil if !data || data.empty?

    if data.is_a?(Array)
      data.map { |el| make_str(el, level) }.compact * "\n"
    else
      str = nil

      if data[:name]
        return make_str(data[:subtree], level) if data[:name] == '__default__'

        str = render_element(data, level)
      end

      if data[:subtree].nil?
        str
      elsif !data[:subtree] && data[:type] != :application
        nil
      else
        [str, make_str(data[:subtree], level + 1)].compact * "\n"
      end
    end
  end

  def render_debug_info(data)
    error!("unexpected server response #{data.inspect}") unless data.is_a?(Hash)

    s = ''

    if config_yaml = data.delete(:config_yaml)
      s << config_yaml

    else
      data.each do |k, v|
        s << "#{"#{k}:".ljust(10)} "

        s << case k
          when :resources
            resources_str(v)
          else
            v.to_s
        end

        s << "\n"
      end

      s << "\n"
    end

    s
  end

  def render_history(data)
    error!("unexpected server response #{data.inspect}") unless data.is_a?(Hash)
    data.map { |name, history| detail_process_info(name, history) }.join("\n")
  end

  def detail_process_info(name, history)
    return if history.empty?

    res = "\033[1m#{name}\033[0m\n"
    history = history.reverse

    history.chunk { |h| [h[:state], h[:reason].to_s] }.each do |_, hist|
      if hist.size >= 3
        res << detail_process_info_string(hist[0])
        res << detail_process_info_string(state: "... #{hist.size - 2} times", reason: '...')
        res << detail_process_info_string(hist[-1])
      else
        hist.each do |h|
          res << detail_process_info_string(h)
        end
      end
    end

    res
  end

  def detail_process_info_string(h)
    state = h[:state].to_s.ljust(14)
    at = h[:at] ? Eye::Utils.human_time2(h[:at]) : '.' * 12
    "#{at} - #{state} (#{h[:reason]})\n"
  end

  def render_element(data, level)
    off = level * 2
    off_str = ' ' * off

    short_state = (data[:type] == :application || data[:type] == :group) && data[:states]
    is_text = data[:state] || data[:states]

    name = (data[:type] == :application && !is_text) ? "\033[1m#{data[:name]}\033[0m" : data[:name].to_s
    off_len = 35
    str = off_str + (name + ' ').ljust(off_len - off, is_text ? '.' : ' ')

    if short_state
      str += ' ' + data[:states].map { |k, v| "#{k}:#{v}" }.join(', ')
    elsif data[:state]
      str += ' ' + data[:state].to_s
      if data[:resources] && data[:state].to_sym == :up
        str += '  (' + resources_str(data[:resources])
        str += ", <#{data[:procline]}>" if data[:procline]
        str += ')'
      end
      if data[:state_reason] && data[:state] == 'unmonitored'
        str += " (#{data[:state_reason]} at #{Eye::Utils.human_time2(data[:state_changed_at])})"
      end
      if debug = data[:debug]
        str += " (#{debug.inspect})"
      end
    elsif data[:current_command]
      chain_progress = if data[:chain_progress]
        " #{data[:chain_progress][0]} of #{data[:chain_progress][1]}" rescue ''
      end
      str += " \e[1;33m[#{data[:current_command]}#{chain_progress}]\033[0m"
      str += " (#{data[:chain_commands] * ', '})" if data[:chain_commands]
    end

    str
  end

  def resources_str(r)
    return '' if !r || r.empty?

    memory = r[:memory]
    cpu = r[:cpu]
    start_time = r[:start_time]
    pid = r[:pid]

    return '' unless memory && cpu && start_time

    "#{Eye::Utils.human_time(start_time)}, #{cpu.to_i}%, #{memory / 1024 / 1024}Mb, <#{pid}>"
  end

end
