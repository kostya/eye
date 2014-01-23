class Eye::Checker::Memory < Eye::Checker::Measure

  # check :memory, :every => 3.seconds, :below => 80.megabytes, :times => [3,5]

  def check_name
    @check_name ||= "memory(#{measure_str})"
  end

  def get_value
    Eye::SystemResources.memory(@pid).to_i
  end

  def human_value(value)
    "#{value.to_i / 1024 / 1024}Mb"
  end

end
