module Eye::Process::Logger

  def additional_logger_tag
    @additional_logger_tag ||= ''
  end

  def additional_logger_tag=(tag)  
    @additional_logger_tag = tag
  end

  Logger::Severity.constants.each do |level|
    method_name = level.to_s.downcase
    define_method(method_name) do |message|
      @logger.send(method_name, message)
    end
  end
  
  def prepare_mes(mes)
    additional_logger_tag + mes
  end

end