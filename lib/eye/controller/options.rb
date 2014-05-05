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
    puts "Warning, set http options in non reel-eye gem" if opts.present?
  end

end