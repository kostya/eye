class Eye::Checker::Socket < Eye::Checker::Defer

  # check :socket, :every => 5.seconds, :times => 1,
  #  :addr => "unix:/var/run/daemon.sock", :timeout => 3.seconds,
  #
  # Available parameters:
  # :addr          the socket addr to open. The format is tcp://<host>:<port> or unix:<path>
  # :timeout       generic timeout for reading data from socket
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
  param :protocol,      [Symbol], nil, nil, [:default, :em_object, :raw]

  def initialize(*args)
    super
    @open_timeout = (open_timeout || 1).to_f
    @read_timeout = (read_timeout || timeout || 5).to_f

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
    sock = begin
      Timeout::timeout(@open_timeout){ open_socket }
    rescue Timeout::Error
      return { :exception => "OpenTimeout<#{@open_timeout}>" }
    end

    if send_data
      begin
        Timeout::timeout(@read_timeout) do
          _write_data(sock, send_data)
          result = _read_data(sock)

          { :result => result }
        end
      rescue Timeout::Error
        if protocol == :raw
          return { :result => @buffer }
        else
          return { :exception => "ReadTimeout<#{@read_timeout}>" }
        end
      end
    else
      { :result => :listen }
    end

  rescue Exception => e
    { :exception => "Error<#{e.message}>" }

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
          mes = "proc match failed with '#{ex.message}'"
          error(mes)
          value[:notice] = mes
          return false
        end

        unless match
          warn "proc #{expect_data} not matched (#{value[:result].truncate(30)}) answer"
          value[:notice] = 'missing proc validation'
        end

        return match
      end

      return true if expect_data.is_a?(Regexp) && expect_data.match(value[:result])
      return true if value[:result].to_s == expect_data.to_s

      warn "#{expect_data} not matched (#{value[:result].truncate(30)}) answer"
      value[:notice] = "missing '#{expect_data.to_s}'"
      return false
    end

    return true
  end

  def human_value(value)
    if !value.is_a?(Hash)
      '-'
    elsif value[:exception]
      value[:exception]
    else
      if value[:result] == :listen
        'listen'
      else
        res = "#{value[:result].to_s.size}b"
        res += "<#{value[:notice]}>" if value[:notice]
        res
      end
    end
  end

private

  def open_socket
    if @socket_family == :tcp
      TCPSocket.open(@socket_addr, @socket_port)
    elsif @socket_family == :unix
      UNIXSocket.open(@socket_path)
    else
      raise "Unknown socket addr #{addr}"
    end
  end

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
      content = ''
      msg_size = socket.recv(4).unpack('N')[0] rescue 0
      content << socket.recv(msg_size - content.length) while content.length < msg_size
      if content.present?
        Marshal.load(content) rescue 'corrupted_marshal'
      end
    when :raw
      @buffer = ''
      loop { @buffer << socket.recv(1) }
    else
      socket.readline.chop
    end
  end

end
