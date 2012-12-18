module Eye::Process::Watchers

  def add_watchers(force = false)
    remove_watchers if force

    if @watchers.blank?
      # default watcher :check_alive
      add_watcher(:check_alive, self[:check_alive_period]) do 
        check_alive
        GC.start if rand(1000) == 0
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
      warn "try add_watchers, but its already here"
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
  
  def clear_watcher(type)
    if @watchers[type]
      @watchers[type][:timer].cancel
      @watchers.delete(type)
    end
  end

  def start_checkers
    self[:checks].each do |_, cfg|
      start_checker(cfg)
    end
  end

  def start_checker(cfg)
    subject = Eye::Checker.create(pid, cfg, logger.prefix)

    # ex: {:type => :mem_usage, :every => 5.seconds, :below => 100.megabytes, :times => [3,5]}
    add_watcher("check_#{cfg[:type]}".to_sym, cfg[:every] || 5, subject) do |watcher|
      queue(:restart) unless watcher.check
    end
  end

end