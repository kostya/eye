require 'json'

class Eye::Http

  def call(env)
    if env['REQUEST_METHOD'] == 'GET'
      if env['REQUEST_PATH'] == '/'
        return [200, {}, [Eye::ABOUT]]
      elsif env['REQUEST_PATH'] =~ /\A\/api\/(\w+)\Z/
        req = Rack::Request.new(env)
        act = $1.to_sym
        if act == :api
          res = Eye::Control.command :raw_info, req.params[:filter].to_s
          return json_response(res)
        elsif [:start, :stop, :restart, :delete, :unmonitor, :monitor].include? act
          res = Eye::Control.command act, req.params[:filter].to_s
          return json_response(res)
        end
      end
    end
    [404, {}, ['PAGE NOT FOUND']]
  end

  def json_response(result)
    headers = { 'Content-Type' => 'application/json; charset=utf-8' }
    [200, headers, [JSON.generate(result: result)]]
  end

end
