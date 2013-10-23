gem 'reel', '~> 0.4.0'
gem 'reel-rack'
gem 'cuba'

require 'reel/rack/server'

class Eye::Http
  autoload :Router,   'eye/http/router'

  attr_reader :server, :host, :port

  def initialize(host, port)
    @host = host
    @port = port.to_i
    @router = Router
  end

  def start
    stop
    @server = Reel::Rack::Server.supervise(@router, :Host => @host, :Port => port)
  end

  def stop
    if @server
      @server.terminate
      @server = nil
    end
  end
end
