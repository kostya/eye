module Eye::Controller::Status

  def status_string_old
  end

  def status_string
    make_str(status_data)
  end

  def status_string_debug
    actors = Celluloid::Actor.all.map{|actor| actor.class }.group_by{|a| a}.map{|k,v| [k, v.size]}.sort_by{|a|a[1]}.reverse

    str = <<-S
#{Eye::ABOUT}
info: #{Eye::SystemResources.info_string($$)}

Actors:
#{actors.inspect}

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
        off = level * 2
        off_str = ' ' * off
        str = off_str + (data[:name].to_s + ' ').ljust(30 - off, data[:state] ? '.' : ' ')
        
        if data[:pid]
          str += " (#{data[:pid].to_s})".ljust(8)
        else
          str += " ".ljust(8, ' ') #if data[:state]
        end

        if data[:debug]
          str += '| ' + data[:debug]
        elsif data[:state]
          str += ': ' + data[:state].to_s 
          str += ' (' + data[:resources] + ')' if data[:resources].present?
        end
      end

      [str, make_str(data[:subtree], level + 1)].compact * "\n"
    end
  end

  def status_data(debug = false)
    {:subtree => @applications.sort_by(&:name).map{|a| a.status_data(debug) } }
  end

end