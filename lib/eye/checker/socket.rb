class Eye::Checker::Socket < Eye::Checker

  # checks :socket, :every => 5.seconds, :times => 1,
  #  :addr => "unix:/var/run/daemon.sock", :timeout => 3.seconds,
  #
  # Available parameters:
  # :addr          the socket addr to open. The format is tcp://<host>:<port> or unix:<path>
  # :timeout       generic timeout for opening the socket or reading data
  # :open_timeout  override generic timeout for the connection
  # :read_timeout  override generic timeout for data read/write
  # :send_data     after connection send this data
  # :expect_data   after sending :send_data expect this response. Can be a string, Regexp or a Proc
  # :protocol      way of pack,unpack messages (default = socket default), example: :protocol => :em_object

  param :addr,          String, true
  param :timeout,       [Fixnum, Float]
  param :open_timeout,  [Fixnum, Float]
  param :read_timeout,  [Fixnum, Float]
  param :send_data
  param :expect_data,   [String, Regexp, Proc]
  param :protocol,      [Symbol]

  def check_name
    'socket'
  end

  def initialize(*args)
    super
    @open_timeout = (open_timeout || 1).to_i
    @read_timeout = (read_timeout || timeout || 5).to_i

    if addr =~ %r[\Atcp://(.*?):(.*?)\z]
      @socket_family = :tcp
      @socket_addr = $1
      @socket_port = $2.to_i
    elsif addr =~ %r[\Aunix:(.*)\z]
      @socket_family = :unix
      @socket_path = $1
    end
  end

  def get_value
    Celluloid::Future.new{ get_value_sync }.value
  end

  def get_value_sync
    sock = Timeout::timeout(@open_timeout) do
      if @socket_family == :tcp      
        TCPSocket.open(@socket_addr, @socket_port)
      elsif @socket_family == :unix
        UNIXSocket.open(@socket_path)
      else
        raise "Unknown socket addr #{addr}"
      end
    end

    if send_data
      Timeout::timeout(@read_timeout) do
        _write_data(sock, send_data)
        { :result => _read_data(sock) }
      end
    else
      { :result => :listen }
    end

  rescue Timeout::Error
    debug 'Timeout error'
    { :exception => :timeout }

  rescue Exception => e
    warn "Exception #{e.message}"
    { :exception => e.message }

  ensure
    sock.close if sock
  end

  def good?(value)
    return false if !value[:result]

    if expect_data
      if expect_data.is_a?(Proc)                
        match = begin
          !!expect_data[value[:result]] 
        rescue Timeout::Error, Exception => ex
          error "proc match failed with #{ex.message}"
          return false
        end
        
        warn "proc #{expect_data} not matched (#{value[:result].truncate(30)}) answer" unless match
        return match
      end

      return true if expect_data.is_a?(Regexp) && expect_data.match(value[:result])
      return true if value[:result].to_s == expect_data.to_s

      warn "#{expect_data} not matched (#{value[:result].truncate(30)}) answer"      
      return false
    end

    return true
  end

  def human_value(value)
    if !value.is_a?(Hash)
      '-'
    elsif value[:exception]
      if value[:exception] == :timeout
        'T-out'
      else
        "Err(#{value[:exception]})"
      end
    else
      if value[:result] == :listen
        "listen"
      else
        "#{value[:result].to_s.size}b"
      end
    end
  end

private

  def _write_data(socket, data)
    case protocol
    when :em_object
      data = Marshal.dump(data)
      socket.write([data.bytesize, data].pack('Na*'))
    else
      socket.write(data.to_s)
    end
  end

  def _read_data(socket)
    case protocol
    when :em_object
      content = ""
      msg_size = socket.recv(4).unpack('N')[0] rescue 0
      content << socket.recv(msg_size - content.length) while content.length < msg_size
      if content.present?
        Marshal.load(content) rescue 'corrupted_marshal'
      end
    else
      socket.readline.chop
    end
  end

end