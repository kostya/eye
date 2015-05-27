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
    Timeout.timeout(Eye::Local.client_timeout) { send_request(pack) }
  rescue Timeout::Error, EOFError
    :timeouted
  end

  def send_request(pack)
    UNIXSocket.open(@socket_path) do |socket|
      socket.write(pack)
      data = socket.read
      Marshal.load(data) rescue :corrupted_data
    end
  end

end
