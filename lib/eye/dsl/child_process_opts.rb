class Eye::Dsl::ChildProcessOpts < Eye::Dsl::Opts

  def allow_options
    [:stop_command, :restart_command, :children_update_period,
      :stop_signals, :stop_grace, :stop_timeout, :restart_timeout]
  end

  def triggers(*args)
    raise Eye::Dsl::Error, 'triggers not allowed in monitor_children'
  end
  alias trigger triggers

end
