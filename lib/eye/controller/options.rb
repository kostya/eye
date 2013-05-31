module Eye::Controller::Options

  def set_opt_logger(logger)
    # do not apply logger, if in stdout state
    if !%w{stdout stderr}.include?(Eye::Logger.dev)
      if logger.blank?
        Eye::Logger.link_logger(nil)
      else
        Eye::Logger.link_logger(logger)
      end
    end
  end

  def set_opt_logger_level(level)
    Eye::Logger.log_level = level
  end

  def set_opt_http(opts = {})
    # stub!
  end

end