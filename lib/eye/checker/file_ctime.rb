class Eye::Checker::FileCTime < Eye::Checker

  # Check that file changes (log for example)
  # check :ctime, :every => 5.seconds, :file => "/tmp/1.log", :times => [3,5]

  param :file, [String], true

  def initialize(*args)
    super
    self.file = process.expand_path(file) if process && file
  end

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
