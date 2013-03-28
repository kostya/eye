module Eye::Process::Watchers

  def add_watchers(force = false)
    return unless self.up?

    remove_watchers if force

    if @watchers.blank?
      # default watcher :check_alive
      add_watcher(:check_alive, self[:check_alive_period]) do 
        check_alive
      end

      # monitor childs pids
      if self[:monitor_children]
        add_watcher(:check_childs, self[:childs_update_period]) do 
          add_or_update_childs
        end
      end

      # monitor conditional watchers
      start_checkers
    else
      warn 'try add_watchers, but its already here'
    end
  end
  
  def remove_watchers
    @watchers.each{|_, h| h[:timer].cancel }
    @watchers = {}
  end

private  

  def add_watcher(type, period = 2, subject = nil, &block)
    return if @watchers[type]

    debug "add watcher #{type}(#{period})"

    timer = every(period.to_f) do
      debug "check #{type}"
      block.call(subject)
    end    

    @watchers[type] ||= {:timer => timer, :subject => subject}
  end  
  
  def start_checkers
    self[:checks].each{|type, cfg| start_checker(cfg) }
  end

  def start_checker(cfg)
    subject = Eye::Checker.create(pid, cfg, logger.prefix)

    # ex: {:type => :memory, :every => 5.seconds, :below => 100.megabytes, :times => [3,5]}
    add_watcher("check_#{cfg[:type]}".to_sym, subject.every, subject, &method(:watcher_tick).to_proc)
  end

  def watcher_tick(subject)
    unless subject.check
      return unless up?
      
      action = subject.fire || :restart
      notify :crit, "Bounded #{subject.check_name}: #{subject.last_human_values} send to :#{action}"
      schedule action, "bounded #{subject.check_name}"
    end
  end

end