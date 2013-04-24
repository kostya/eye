class Eye::Dsl::ChildProcessOpts < Eye::Dsl::Opts

  def allow_options
    [:stop_command, :restart_command, :childs_update_period,
      :stop_signals, :stop_grace, :stop_timeout, :restart_timeout]
  end

end