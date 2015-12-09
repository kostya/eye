require 'socket'
require 'timeout'

class Eye::Client

  attr_reader :socket_path

  def initialize(socket_path)
    @socket_path = socket_path
  end

  def execute(h = {})
    payload = Marshal.dump(h)
    payload = payload.length.to_s + "\n" + payload
    timeout = h[:timeout] || Eye::Local.client_timeout
    attempt_command(payload, timeout)
  end

private

  def attempt_command(payload, timeout)
    Timeout.timeout(timeout) { send_request(payload) }
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
