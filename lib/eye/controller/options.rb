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

  def set_opt_http(params = {})
    if params[:enable]
      if @http
        if params[:host] != @http.host || params[:host].to_i != @http.host
          stop_http
          start_http(params[:host], params[:port])
        end
      else
        start_http(params[:host], params[:port])
      end
    else
      stop_http if @http
    end
  end

private

  def stop_http
    if @http
      @http.stop
      @http = nil
    end
  end

  def start_http(host, port)
    require 'eye/http' # ruby 2.0 autoload bug
    @http = Eye::Http.new(host, port)
    @http.start
  end
  
end