class Eye::Checker::Runtime < Eye::Checker

  # check :runtime, :every => 1.minute, :below => 120.minutes

  param :below, [Fixnum, Float], true

  def get_value
    st = Eye::SystemResources.start_time(@pid)
    if st
      Time.now.to_i - st.to_i
    else
      0
    end
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