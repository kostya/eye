class Eye::Checker::ChildrenMemory < Eye::Checker::Measure

  # check :children_memory, :every => 30.seconds, :below => 400.megabytes
  #   monitor_children should be enabled

  def check_name
    @check_name ||= "children_memory(#{measure_str})"
  end

  def get_value
    process.children.values.inject(0) do |sum, ch|
      sum + Eye::SystemResources.memory(ch.pid).to_i
    end
  end

  def human_value(value)
    "#{value.to_i / 1024 / 1024}Mb"
  end

end
