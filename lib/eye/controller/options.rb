module Eye::Controller::Options

  def set_opt_logger(logger_args)
    # do not apply logger, if in stdout state
    unless %w[stdout stderr].include?(Eye::Logger.dev)
      Eye::Logger.link_logger(*logger_args)
    end
  end

  def set_opt_logger_level(level)
    Eye::Logger.log_level = level
  end

end
