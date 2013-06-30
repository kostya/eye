gem 'reel', '~> 0.4.0.pre'
gem 'cuba'

require 'reel'

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
