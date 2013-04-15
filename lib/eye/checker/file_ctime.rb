class Eye::Checker::FileCTime < Eye::Checker

  # Check that file changes (log for example)

  # checks :ctime, :every => 5.seconds, :file => "/tmp/1.log", :times => [3,5]

  param :file, [String], true

  def get_value
    File.ctime(file) rescue nil
  end

  def human_value(value)
    if value == nil
      'Err'
    else
      value.strftime('%H:%M')
    end
  end

  def good?(value)
    value.to_i > previous_value.to_i
  end

end