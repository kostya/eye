class Eye::Checker::FileTouched < Eye::Checker

  param :file, [String], true
  param :delete, [TrueClass, FalseClass]

  def initialize(*args)
    super
    self.file = process.expand_path(file) if process && file
  end

  def get_value
    File.exists?(file)
  end

  def good?(value)
    File.delete(file) if value && delete
    !value
  end

end
