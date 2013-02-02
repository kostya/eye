require 'reel'
require 'sinatra'
require 'json'

class Eye::Http < Sinatra::Base

  helpers do
    def json_body(result)
      @response['Content-Type'] = 'application/json; charset=utf-8'
      JSON.generate(result: result)
    end
  end

  get '/' do
    Eye::ABOUT
  end

  [:start, :stop, :restart, :delete, :unmonitor, :monitor].each do |act|
    get "/api/#{act}" do
      res = Eye::Control.command act, params[:filter].to_s
      json_body(res)
    end
  end

  get "/api/info" do
    res = Eye::Control.command :object_info, params[:filter].to_s
    json_body(res)
  end

end
