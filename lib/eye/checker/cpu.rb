class Eye::Checker::Cpu < Eye::Checker

  # ex: {:type => :cpu, :every => 3.seconds, :below => 80, :times => 3},

  params :below
  
  def check_name
    "cpu"
  end

  def get_value(pid)
    Eye::SystemResources.cpu_usage(pid).to_i # nil => 0
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