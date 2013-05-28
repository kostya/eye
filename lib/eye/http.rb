require 'reel'
require 'sinatra'
require 'json'

class Eye::Http

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

  class Router < Sinatra::Base
    helpers do
      def json_body(result)
        @response['Content-Type'] = 'application/json; charset=utf-8'
        { result: result }.to_json
      end
    end

    get '/' do
      Eye::ABOUT
    end

    [:start, :stop, :restart, :delete, :unmonitor, :monitor].each do |act|
      put "/api/#{act}" do
        res = Eye::Control.command act, params[:filter].to_s
        json_body(res)
      end
    end

    get "/api/info" do
      res = Eye::Control.command :raw_info, params[:filter].to_s
      json_body(res)
    end

    not_found { halt 404, 'Page not found' }
    error { halt 404, 'Page not found' }
  end

end
