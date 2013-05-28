require 'reel'

class Eye::Http
  autoload :Router,   'eye/http/router'

  attr_reader :server

  def initialize(host, port)
    @host = host
    @port = port
    @router = Router.new
  end

  def start
    stop 

    @server = Reel::Server.supervise(@host, @port) do |connection|
      while request = connection.request
        status, headers, body = @router.call(Rack::MockRequest.env_for(request.url, :method => request.method, :input => request.body))
        connection.respond(Reel::Response.new(status, headers, body))
      end
    end
  end

  def stop
    if @server
      @server.terminate
      @server = nil
    end
  end
end
