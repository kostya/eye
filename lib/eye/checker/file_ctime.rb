class Eye::Checker::FileCTime < Eye::Checker

  # ex: {:type => :ctime, :every => 5.seconds, :file => "/tmp/1.log", :times => [3,5]}

  params :file

  def check_name
    'ctime'
  end

  def get_value(pid)
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