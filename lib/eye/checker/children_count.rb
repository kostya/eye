class Eye::Checker::ChildrenCount < Eye::Checker::Measure

  # check :children_count, :every => 30.seconds, :below => 10, :strategy => :kill_old
  #   monitor_children should be enabled

  param :strategy, Symbol, nil, :restart, [:restart, :kill_old, :kill_new]

  def get_value
    process.children.size
  end

  def fire
    if strategy == :restart
      super
    else
      pids = ordered_by_date_children_pids

      pids = if strategy == :kill_old
        pids[0...-below]
      else
        pids[below..-1]
      end

      kill_pids(pids)
    end
  end

private

  def kill_pids(pids)
    info "killing pids: #{pids.inspect} for strategy: #{strategy}"
    pids.each do |pid|
      if child = process.children[pid]
        child.schedule :stop, Eye::Reason.new("bounded #{check_name}")
      end
    end
  end

  def ordered_by_date_children_pids
    children = process.children.values
    children.sort_by { |ch| Eye::SystemResources.start_time(ch.pid).to_i }.map &:pid
  end

end
