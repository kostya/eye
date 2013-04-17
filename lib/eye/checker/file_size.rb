class Eye::Checker::FileSize < Eye::Checker

  # Check that file size changed (log for example)

  # checks :fsize, :every => 5.seconds, :file => "/tmp/1.log", :times => [3,5], 
  #      :below => 30.kilobytes, :above => 10.kilobytes

  param :file, [String], true
  param :below, [Fixnum, Float]
  param :above, [Fixnum, Float]

  def get_value
    File.size(file) rescue nil
  end

  def human_value(value)
    "#{value.to_i / 1024}Kb"
  end

  def good?(value)
    return true unless previous_value

    diff = value.to_i - previous_value.to_i

    return true if diff < 0 # case when logger nulled

    return false if below && diff > below
    return false if above && diff < above
    return false if diff == 0

    true
  end

end