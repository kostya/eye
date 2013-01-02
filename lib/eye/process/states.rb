gem 'state_machine'
require 'state_machine'

class Eye::Process

  # do transition
  def switch(name, state_reason = nil)
    self.send("#{name}!")
    @state_reason = state_reason
  end

  state_machine :state, :initial => :unmonitored do
    state :unmonitored, :up, :down
    state :starting, :stopping, :restarting

    event :starting do
      transition [:unmonitored, :down] => :starting
    end

    event :already_running do
      transition [:unmonitored, :down, :up] => :up
    end

    event :started do
      transition :starting => :up
    end

    event :crushed do
      transition [:starting, :restarting, :up] => :down
    end

    event :stopping do
      transition [:up, :restarting] => :stopping
    end

    event :stopped do
      transition :stopping => :down
    end

    event :cant_kill do
      transition :stopping => :up
    end

    event :restarting do
      transition [:unmonitored, :up, :down] => :restarting
    end

    event :restarted do
      transition :restarting => :up
    end

    event :unmonitoring do
      transition any => :unmonitored
    end

    after_transition :on => :crushed, :do => :on_crushed
    after_transition any => :unmonitored, :do => :on_unmonitored
    after_transition any-:up => :up, :do => :on_up
    after_transition :up => any-:up, :do => :from_up
    after_transition any => any, :do => :log_transition
    after_transition any => any, :do => :upd_for_triggers
  end

  def on_crushed
    check_crush!
  end

  def on_unmonitored
    self.flapping = false
    self.pid = nil
  end

  def on_up
    add_watchers!
    add_childs!
  end

  def from_up
    remove_watchers
    remove_childs
  end

  def log_transition(transition)
    @states_history << transition.to_name
    info "switch [:#{transition.from_name} => :#{transition.to_name}]"
  end

  def upd_for_triggers(transition)
    check_triggers
  end

end