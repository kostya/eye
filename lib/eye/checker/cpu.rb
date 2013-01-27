class Eye::Checker::Cpu < Eye::Checker

  # checks :cpu, :every => 3.seconds, :below => 80, :times => [3,5]

  param :below, [Fixnum, Float], true

  def check_name
    "cpu(#{human_value(below)})"
  end

  def get_value
    Eye::SystemResources.cpu_usage(@pid).to_i # nil => 0
  end

  def human_value(value)
    "#{value}%"
  end

  def good?(value)
    if below
      value < below
    else
      true
    end
  end

end