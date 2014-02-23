class Eye::Checker::Runtime < Eye::Checker::Measure

  # check :runtime, :every => 1.minute, :below => 120.minutes

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

end
