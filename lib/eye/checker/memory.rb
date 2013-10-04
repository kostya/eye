class Eye::Checker::Memory < Eye::Checker

  # checks :memory, :every => 3.seconds, :below => 80.megabytes, :times => [3,5]

  param :below, [Fixnum, Float], true

  def check_name
    @check_name ||= "memory(#{human_value(below)})"
  end

  def get_value
    Eye::SystemResources.memory(@pid).to_i
  end

  def human_value(value)
    "#{value.to_i / 1024 / 1024}Mb"
  end

  def good?(value)
    if below
      value < below
    else
      true
    end
  end

end