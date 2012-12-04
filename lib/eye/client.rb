require 'socket'
require 'timeout'

class Eye::Client
  attr_reader :socket_path
  
  def initialize(socket_path)
    @socket_path = socket_path
  end
  
  def command(cmd, *args)
    attempt_command([cmd, *args] * ':')
  end
  
  def attempt_command(pack)
    Timeout.timeout(Eye::Settings.client_timeout) do
      return send_request(pack)
    end

  rescue Timeout::Error, EOFError
    :timeouted
  end

  def send_request(pack)
    UNIXSocket.open(@socket_path) do |socket|
      socket.puts(pack)
      data = socket.read
      res = Marshal.load(data) rescue :corrupred_marshal
    end
  end
  
end