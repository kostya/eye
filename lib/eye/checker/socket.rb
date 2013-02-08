class Eye::Checker::Socket < Eye::Checker

  # checks :socket, :every => 5.seconds, :times => 1,
  #  :path => "unix:/var/run/daemon.sock", :timeout => 3.seconds,
  #
  # Available parameters:
  # :path          the socket path to open. The format is tcp:<address>:<port> or unix:<path>
  # :timeout       generic timeout for opening the socket or reading data
  # :open_timeout  override generic timeout for the connection
  # :read_timeout  override generic timeout for data read/write
  # :send_data     after connection send this data
  # :expect_data   after sending :send_data expect this response. Can be a string or a Regexp
  #

  param :path, String, true
  param :timeout, [Fixnum, Float]
  param :open_timeout, [Fixnum, Float]
  param :read_timeout, [Fixnum, Float]
  param :send_data, String
  param :expect_data, [String, Regexp]

  attr_reader :session, :uri

  def check_name
    'socket'
  end

  def initialize(*args)
    super

    @open_timeout = (open_timeout || timeout || 5).to_i
    @read_timeout = (read_timeout || timeout || 30).to_i

    if path =~ /^tcp:(.*?):(.*?)$/
      @socket_family = :tcp
      @socket_addr = $1
      @socket_port = $2.to_i
    elsif path =~ /^unix:(.*)$/
      @socket_family = :unix
      @socket_path = $1
    else
      raise "Cannot parse socket path #{path}"
    end
  end

  def get_value
    Celluloid::Future.new{ get_value_sync }.value
  end

  def get_value_sync
    sock = nil

    if @socket_family == :tcp
      sock = TCPSocket.new(@socket_addr, @socket_port)
    elsif @socket_family == :unix
      sock = UNIXSocket.new(@socket_path)
    end

    Timeout::timeout(@read_timeout) do
      sock.write(@send_data) if @send_data

      return { :result => sock.readline.chop }
    end
  rescue Timeout::Error
    debug 'Timeout error'
    { :exception => :timeout }
  rescue Exception => e
    debug 'Exception'
    { :exception => e.message }
  end

  def good?(value)
    return false if !value[:result]

    if @expect_data
      if value[:result].is_a?(Regexp) && !@expect_data.match(value[:result]) ||
         value[:result] != @expect_data
        return false
      end
    end

    return true
  end

  def human_value(value)
    if !value.is_a?(Hash)
      '-'
    elsif value[:exception]
      if value[:exception] == :timeout
        'Socket timeout'
      else
        value[:exception]
      end
    else
      value[:result]
    end
  end

end
