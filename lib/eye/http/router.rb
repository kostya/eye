require 'cuba'
require 'json'

Eye::Http::Router = Cuba.new do

  def json(result)
    res.headers['Content-Type'] = 'application/json; charset=utf-8'
    res.write({ result: result }.to_json)
  end

  on root do
    res.write Eye::ABOUT
  end

  on "api/info", param("filter") do |filter|
    json Eye::Control.command(:info_data, filter)
  end

  [:start, :stop, :restart, :delete, :unmonitor, :monitor].each do |act|
    on put, "api/#{act}", param("filter") do |filter|
      json Eye::Control.command(act, filter)
    end
  end

end
