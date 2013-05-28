require 'sinatra'
require 'json'

class Eye::Http::Router < Sinatra::Base
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
