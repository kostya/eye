class Eye::Checker::TailLog < Eye::Checker

  # ex: {:type => :tail_log, :every => 5.seconds, :log_file => "/tmp/1.log", :times => [3,5]}

  params :log_file

  def check_name
    "tail_log"
  end

  def get_value(pid)
    File.size(log_file) rescue -1
  end

  def good?(value)
    previous_value != value
  end

  def max_tries
    super + 1
  end

  def min_tries
    super - 1
  end

end