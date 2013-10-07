require 'socket'
require 'timeout'

class Eye::Client
  attr_reader :socket_path

  def initialize(socket_path)
    @socket_path = socket_path
  end

  def command(cmd, *args)
    attempt_command(Marshal.dump([cmd, *args]))
  end

  def attempt_command(pack)
    Timeout.timeout(Eye::Local.client_timeout) do
      return send_request(pack)
    end

  rescue Timeout::Error, EOFError
    :timeouted
  end

  def send_request(pack)
    UNIXSocket.open(@socket_path) do |socket|
      socket.write(pack)
      data = socket.read
      res = Marshal.load(data) rescue :corrupted_data
    end
  end

end
