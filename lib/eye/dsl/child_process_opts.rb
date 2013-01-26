class Eye::Dsl::ChildProcessOpts < Eye::Dsl::Opts

  def allow_options
    [:stop_command, :restart_command, :childs_update_period]
  end

  def opts_name
  end

end