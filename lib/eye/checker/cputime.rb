class Eye::Checker::Cputime < Eye::Checker::Measure

  # check :cputime, :every => 1.minute, :below => 120.minutes

  def get_value
    Eye::SystemResources.cputime(@pid).to_f
  end

  def human_value(value)
    "#{value / 60}m"
  end

end
