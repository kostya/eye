module Eye::Controller::Options

  def set_opt_logger(logger_args)
    # do not apply logger, if in stdout state
    if !%w{stdout stderr}.include?(Eye::Logger.dev)
      Eye::Logger.link_logger(*logger_args)
    end
  end

  def set_opt_logger_level(level)
    Eye::Logger.log_level = level
  end

  def set_opt_http(opts = {})
    warn "Warning, set http options not in reel-eye gem" if opts.present?
  end

end
