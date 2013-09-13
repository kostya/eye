class Eye::Checker::Cputime < Eye::Checker

  # check :cputime, :every => 1.minute, :below => 120.minutes

  param :below, [Fixnum, Float], true

  def get_value
    Eye::SystemResources.cputime(@pid).to_f
  end

  def human_value(value)
    "#{value / 60}m"
  end

  def good?(value)
    if below
      value < below
    else
      true
    end
  end

end