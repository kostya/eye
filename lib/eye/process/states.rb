require 'state_machines'
require 'state_machines/version'

class Eye::Process

  class StateError < RuntimeError; end

  # do transition
  def switch(name, call = {})
    @state_call = @last_scheduled_call ? @last_scheduled_call.merge(call) : call
    self.send("#{name}!")
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

    event :crashed do
      transition [:starting, :restarting, :stopping, :up] => :down
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

    after_transition any => any, :do => :log_transition
    after_transition any => any, :do => :check_triggers

    after_transition any => :unmonitored, :do => :on_unmonitored

    after_transition any - :up => :up, :do => :add_watchers
    after_transition :up => any - :up, :do => :remove_watchers

    after_transition any - :up => :up, :do => :add_children
    after_transition any => [:unmonitored, :down], :do => :remove_children

    after_transition :on => :crashed, :do => :on_crashed
  end

  def on_crashed
    self.pid = nil
    schedule command: :check_crash, reason: :crashed
  end

  def on_unmonitored
    self.pid = nil
  end

  def log_transition(transition)
    if transition.to_name != transition.from_name || @state_call[:by] == :user
      reason_str = reason_from_call(@state_call)
      @states_history.push transition.to_name, reason_str
      info "switch :#{transition.event} [:#{transition.from_name} => :#{transition.to_name}] #{reason_str}"
    end
  end

end
