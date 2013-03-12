require 'net/http'

class Eye::Checker::Http < Eye::Checker

  # checks :http, :every => 5.seconds, :times => 1,
  #  :url => "http://127.0.0.1:3000/", :kind => :success, :pattern => /OK/, :timeout => 3.seconds

  param :url,           String, true
  param :pattern,       [String, Regexp]
  param :kind
  param :timeout,       [Fixnum, Float]
  param :open_timeout,  [Fixnum, Float]
  param :read_timeout,  [Fixnum, Float]

  attr_reader :session, :uri

  def check_name
    'http'
  end

  def initialize(*args)
    super

    @uri = URI.parse(url) rescue URI.parse('http://127.0.0.1')
    @pattern = pattern
    @kind = case kind
              when Fixnum then Net::HTTPResponse::CODE_TO_OBJ[kind]
              when String, Symbol then Net.const_get("HTTP#{kind.to_s.camelize}") rescue Net::HTTPSuccess
            else
              Net::HTTPSuccess
            end
    @open_timeout = (open_timeout || 3).to_i
    @read_timeout = (read_timeout || timeout || 15).to_i

    @session = Net::HTTP.new(@uri.host, @uri.port)
    if @uri.scheme == 'https'
      require 'net/https'
      @session.use_ssl=true
      @session.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    @session.open_timeout = @open_timeout
    @session.read_timeout = @read_timeout
  end

  def get_value
    Celluloid::Future.new{ get_value_sync }.value
  end

  def get_value_sync
    res = @session.start do |http|
      http.get(@uri.path)
    end

    {:result => res}

  rescue Timeout::Error
    debug 'Timeout error'
    {:exception => :timeout}

  rescue => ex
    error "Exception #{ex.message}"
    {:exception => ex.message}
  end

  def good?(value)
    return false unless value[:result]
    return false unless value[:result].kind_of?(@kind)

    if @pattern
      if @pattern.is_a?(Regexp)
        @pattern.match(value[:result].body)
      else
        value[:result].body.include?(@pattern.to_s)
      end
    else
      true
    end
  end

  def human_value(value)
    if !value.is_a?(Hash)
      '-'
    elsif value[:exception]
      if value[:exception] == :timeout
        'T-out'
      else
        'Err'
      end
    else
      "#{value[:result].code}=#{value[:result].body.size/ 1024}Kb"
    end
  end

end