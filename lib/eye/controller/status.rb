module Eye::Controller::Status

  def info_objects(mask = nil)
    res = []
    return @applications unless mask
    matched_objects(mask){|obj| res << obj }    
    res
  end

  def info_data(mask = nil)
    {:subtree => info_objects(mask).map{|a| a.status_data } }
  end

  def info_data_debug(mask = nil)
    {:subtree => info_objects(mask).map{|a| a.status_data(true) } }
  end

  def info_string(mask = nil)
    make_str(info_data(mask)).to_s
  end

  def info_string_short
    make_str({:subtree => @applications.map{|a| a.status_data_short } }).to_s
  end

  def info_string_debug(show_config = false, show_processes = false)
    actors = Celluloid::Actor.all.map{|actor| actor.instance_variable_get(:@klass) }.group_by{|a| a}.map{|k,v| [k, v.size]}.sort_by{|a|a[1]}.reverse

    str = <<-S
About:  #{Eye::ABOUT}
Info:   #{resources_str(Eye::SystemResources.resources($$), false)}
Logger: #{Eye::Logger.dev}
Socket: #{Eye::Settings::socket_path}
PidPath: #{Eye::Settings::pid_path}
Actors: #{actors.inspect}

    S

    str += make_str(info_data_debug) + "\n" if show_processes.present?

    if show_config.present?
      str += "\nCurrent config: \n"
      str += YAML.dump(current_config)
    end

    GC.start
    str
  end

private  

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

  def resources_str(r, mb = true)
    return '' if r.blank?
    
    res = "#{r[:start_time]}, #{r[:cpu]}%"

    if r[:memory]
      mem = mb ? "#{r[:memory] / 1024}Mb" : "#{r[:memory]}Kb"
      res += ", #{mem}"
    end

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

end