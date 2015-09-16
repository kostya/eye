module Eye::Process::Watchers

  def add_watchers(force = false)
    return unless self.up?

    remove_watchers if force

    if @watchers.blank?
      # default watcher :check_alive
      add_watcher(:check_alive, self[:check_alive_period]) do
        check_alive
      end

      if self[:check_identity]
        add_watcher(:check_identity, self[:check_identity_period]) do
          check_identity
        end
      end

      # monitor children pids
      if self[:monitor_children]
        add_watcher(:check_children, self[:children_update_period]) do
          add_or_update_children
        end
      end

      # monitor conditional watchers
      start_checkers
    else
      warn 'add_watchers failed, watchers are already present'
    end
  end

  def remove_watchers
    @watchers.each{|_, h| h[:timer].cancel }
    @watchers = {}
  end

private

  def add_watcher(type, period = 2, subject = nil, &block)
    return if @watchers[type]

    debug { "adding watcher: #{type}(#{period})" }

    timer = every(period.to_f) do
      debug { "check #{type}" }
      block.call(subject)
    end

    @watchers[type] ||= {:timer => timer, :subject => subject}
  end

  def start_checkers
    self[:checks].each{|name, cfg| start_checker(name, cfg) }
  end

  def start_checker(name, cfg)
    subject = Eye::Checker.create(pid, cfg, current_actor)

    # ex: {:type => :memory, :every => 5.seconds, :below => 100.megabytes, :times => [3,5]}
    add_watcher("check_#{name}".to_sym, subject.every, subject, &method(:watcher_tick).to_proc) if subject
  end

  def watcher_tick(subject)
    unless subject.check
      return unless up?
      subject.fire
    end
  end

end
