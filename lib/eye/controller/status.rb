module Eye::Controller::Status

  def info_string(*args)
    make_str(info_data(*args)).to_s
  end

  def info_string_short(*args)
    make_str({:subtree => @applications.map{|a| a.status_data_short } }).to_s
  end

  def info_string_debug(*args)
    h = args.extract_options!
    actors = Celluloid::Actor.all.map{|actor| actor.__klass__ }.group_by{|a| a}.map{|k,v| [k, v.size]}.sort_by{|a|a[1]}.reverse

    str = <<-S
About:  #{Eye::ABOUT}
Info:   #{resources_str(Eye::SystemResources.resources($$))}
Ruby:   #{RUBY_DESCRIPTION}
Gems:   #{%w|Celluloid Celluloid::IO ActiveSupport StateMachine NIO|.map{|c| gem_version(c) }}
Checks: #{Eye::Checker::TYPES}, #{Eye::Trigger::TYPES}
Logger: #{Eye::Logger.dev}
Socket: #{Eye::Settings::socket_path}
Pid:    #{Eye::Settings::pid_path}
Actors: #{actors.inspect}

    S

    str += make_str(info_data_debug) + "\n" if h[:processes].present?

    if h[:config].present?
      str += "\nCurrent config: \n"
      str += YAML.dump(current_config.to_h)
    end

    GC.start
    str
  end

  def info_data(*args)
    {:subtree => info_objects(*args).map{|a| a.status_data } }
  end

private

  def info_data_debug(*args)
    {:subtree => info_objects(*args).map{|a| a.status_data(true) } }
  end

  def info_objects(*args)
    res = []
    return @applications if args.empty?
    matched_objects(*args){|obj| res << obj }
    res
  end

  def make_str(data, level = -1)
    return nil if data.blank?

    if data.is_a?(Array)
      data.map{|el| make_str(el, level) }.compact * "\n"
    else
      str = nil

      if data[:name]
        return make_str(data[:subtree], level) if data[:name] == '__default__'

        off = level * 2
        off_str = ' ' * off
        name = (data[:type] == :application && data[:state].blank?) ? "\033[1m#{data[:name]}\033[0m" : data[:name].to_s
        off_len = (data[:type] == :application && !data[:state].blank?) ? 20 : 35
        str = off_str + (name + ' ').ljust(off_len - off, data[:state] ? '.' : ' ')

        if data[:debug]
          str += ' | ' + debug_str(data[:debug])

          # for group show chain data
          if data[:debug][:chain]
            str += " (chain: #{data[:debug][:chain].map(&:to_i)})"
          end
        elsif data[:state]
          str += ' ' + data[:state].to_s
          str += '  (' + resources_str(data[:resources]) + ')' if data[:resources].present? && data[:state].to_sym == :up
          str += " (#{data[:state_reason]} at #{data[:state_changed_at].to_s(:short)})" if data[:state_reason] && data[:state] == 'unmonitored'
        elsif data[:current_command]
          chain_progress = if data[:chain_progress]
            " #{data[:chain_progress][0]} of #{data[:chain_progress][1]}" rescue ''
          end
          str += " \e[1;33m[#{data[:current_command]}#{chain_progress}]\033[0m"
          str += " (#{data[:chain_commands] * ', '})" if data[:chain_commands]
        end

      end

      if data[:subtree].nil?
        str
      elsif data[:subtree].blank? && data[:type] != :application
        nil
      else
        [str, make_str(data[:subtree], level + 1)].compact * "\n"
      end
    end
  end

  def resources_str(r)
    return '' if r.blank?

    res = "#{r[:start_time]}, #{r[:cpu]}%"
    res += ", #{r[:memory] / 1024}Mb" if r[:memory]
    res += ", <#{r[:pid]}>"

    res
  end

  def debug_str(debug)
    return '' unless debug

    q = 'q(' + (debug[:queue] || []) * ',' + ')'
    w = 'w(' + (debug[:watchers] || []) * ',' + ')'

    [w, q] * '; '
  end

  def status_applications(app = nil)
    apps = app.present? ? @applications.select{|a| a.name == app} : nil
    apps = @applications unless apps
    apps
  end

  def gem_version(klass)
    v = nil
    begin
      v = eval("#{klass}::VERSION::STRING")
    rescue
      v = eval("#{klass}::VERSION") rescue ''
    end
    "#{klass}=#{v}"
  end

end