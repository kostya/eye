require 'socket'
require 'timeout'

class Eye::Client
  attr_reader :socket_path
  
  def initialize(socket_path)
    @socket_path = socket_path
  end
  
  def command(cmd, *args)
    pack = [cmd, *args] * ':'
    attempt_command(pack)
  end
  
  def attempt_command(pack)
    res = nil
    Timeout.timeout(Eye::Settings.client_timeout){ res = send_request(pack) }
    res
    
  rescue Timeout::Error, EOFError
    :timeouted
  end

  def send_request(pack)
    UNIXSocket.open(@socket_path) do |socket|
      socket.puts(pack)
      data = socket.read
      res = Marshal.load(data) rescue nil
    end
  end
  
end