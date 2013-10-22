class Eye::Checker::FileTouched < Eye::Checker

  param :file, [String], true
  param :delete, [TrueClass, FalseClass]

  def get_value
    File.exists?(file)
  end

  def good?(value)
    File.delete(file) if value && delete
    !value
  end

end
