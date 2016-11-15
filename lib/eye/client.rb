require 'socket'
require 'timeout'

class Eye::Client

  attr_reader :socket_path

  def initialize(socket_path, type = :old)
    @socket_path = socket_path
    @type = type
  end

  SIGN = 123_566_983

  def execute(h = {})
    payload = if @type == :old
      Marshal.dump([h[:command], *h[:args]]) # TODO: remove in 1.0
    else
      payload = Marshal.dump(h)
      [SIGN, payload.length].pack('N*') + payload
    end
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
