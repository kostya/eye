module Eye::Controller::Status

  def debug_data(*args)
    h = args.extract_options!
    actors = Celluloid::Actor.all.map{|actor| actor.wrapped_object.class.to_s }.group_by{|a| a}.map{|k,v| [k, v.size]}.sort_by{ |a| a[1] }.reverse

    res = {
      :about => Eye::ABOUT,
      :resources => Eye::SystemResources.resources($$),
      :ruby => RUBY_DESCRIPTION,
      :gems => %w|Celluloid Celluloid::IO StateMachine NIO Timers Sigar|.map{|c| gem_version(c) },
      :logger => Eye::Logger.args.present? ? [Eye::Logger.dev.to_s, *Eye::Logger.args] : Eye::Logger.dev.to_s,
      :dir => Eye::Local.dir,
      :pid_path => Eye::Local::pid_path,
      :sock_path => Eye::Local::socket_path,
      :actors => actors,
      :celluloid_backported => $CELLULOID_BACKPORTED
    }

    res[:config_yaml] = YAML.dump(current_config.to_h) if h[:config].present?

    res
  end

  def info_data(*args)
    {:subtree => info_objects(*args).map{|a| a.status_data } }
  end

  def short_data(*args)
    {:subtree => info_objects(*args).select{ |o| o.class == Eye::Application }.map{|a| a.status_data_short } }
  end

  def history_data(*args)
    res = {}
    history_objects(*args).each do |process|
      res[process.full_name] = process.schedule_history.reject{|c| c[:state] == :check_crash }
    end
    res
  end

private

  def info_objects(*args)
    res = []
    return @applications if args.empty?
    matched_objects(*args){|obj| res << obj }
    res
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

  def history_objects(*args)
    args = ['*'] if args.empty?
    res = []
    matched_objects(*args) do |obj|
      if obj.is_a?(Eye::Process)
        res << obj
      elsif obj.is_a?(Eye::ChildProcess)
      else
        res += obj.processes.to_a
      end
    end
    Eye::Utils::AliveArray.new(res)
  end

end
