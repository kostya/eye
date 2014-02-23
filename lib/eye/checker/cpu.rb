class Eye::Checker::Cpu < Eye::Checker::Measure

  # check :cpu, :every => 3.seconds, :below => 80, :times => [3,5]

  def check_name
    @check_name ||= "cpu(#{measure_str})"
  end

  def get_value
    Eye::SystemResources.cpu(@pid).to_i # nil => 0
  end

  def human_value(value)
    "#{value}%"
  end

end
