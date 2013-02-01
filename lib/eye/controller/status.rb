module Eye::Controller::Status

  def status_string(app = nil)
    make_str(status_data(false, app))
  end

  def status_string_debug
    actors = Celluloid::Actor.all.map{|actor| actor.instance_variable_get(:@klass) }.group_by{|a| a}.map{|k,v| [k, v.size]}.sort_by{|a|a[1]}.reverse

    str = <<-S
About:  #{Eye::ABOUT}
Info:   #{resources_str(Eye::SystemResources.resources($$), false)}
Logger: #{Eye::Logger.dev}
Actors: #{actors.inspect}

#{make_str(status_data(true))}
    S

    GC.start
    str
  end

private  

  def make_str(data, level = -1)
    if data.is_a?(Array)
      data.map{|el| make_str(el, level) } * "\n"
    elsif data.nil?              
    else
      str = nil

      if data[:name]
        return make_str(data[:subtree], level) if data[:name] == '__default__'

        off = level * 2
        off_str = ' ' * off
        str = off_str + (data[:name].to_s + ' ').ljust(35 - off, data[:state] ? '.' : ' ')

        if data[:debug]
          str += ' | ' + debug_str(data[:debug])

          # for group show chain data
          if data[:debug][:chain]
            str += " (chain: #{data[:debug][:chain].map(&:to_i)})"
          end
        elsif data[:state]
          str += ' ' + data[:state].to_s 
          str += '  (' + resources_str(data[:resources]) + ')' if data[:resources].present? && data[:state].to_sym == :up
        elsif data[:current_command]
          str += " [#{data[:current_command]}]"
        end

      end

      [str, make_str(data[:subtree], level + 1)].compact * "\n"
    end
  end

  REV_REGX = /r:([a-z0-9]{5,})/i

  def resources_str(r, mb = true)
    return '' if r.blank?
    
    res = "#{r[:start_time]}, #{r[:cpu]}%"

    if r[:memory]
      mem = mb ? "#{r[:memory] / 1024}Mb" : "#{r[:memory]}Kb"
      res += ", #{mem}"
    end

    # show process revision, as parse from procline part: 'r:12345678'
    if r[:command] && r[:command].to_s =~ REV_REGX
      res += ", #{$1.to_s[0..5]}"
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
    apps = app ? @applications.select{|a| a.name == app} : nil
    apps = @applications unless apps
    apps
  end

  def status_data(debug = false, app = nil)
    {:subtree => status_applications(app).sort_by(&:name).map{|a| a.status_data(debug) } }
  end

end