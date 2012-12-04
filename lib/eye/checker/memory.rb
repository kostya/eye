class Eye::Checker::Memory < Eye::Checker

  # ex: {:type => :memory, :every => 5.seconds, :below => 100.megabytes, :times => [3,5]}

  params :below
  
  def check_name
    "memory"
  end

  def get_value(pid)
    Eye::SystemResources.memory_usage(pid).to_i * 1024
  end

  def human_value(value)
    "#{value / 1024 / 1024}Mb"    
  end

  def good?(value)
    if below
      value < below
    else
      true
    end
  end

end