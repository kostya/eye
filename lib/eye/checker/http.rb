require 'net/http'

class Eye::Checker::Http < Eye::Checker::Defer

  # check :http, :every => 5.seconds, :times => 1,
  #  :url => "http://127.0.0.1:3000/", :kind => :success, :pattern => /OK/, :timeout => 3.seconds

  param :url,           String, true
  param :pattern,       [String, Regexp]
  param :kind,          [String, Fixnum, Symbol]
  param :timeout,       [Fixnum, Float]
  param :open_timeout,  [Fixnum, Float]
  param :read_timeout,  [Fixnum, Float]

  attr_reader :uri

  def initialize(*args)
    super

    @uri = URI.parse(url)
    @kind = case kind
              when Fixnum then Net::HTTPResponse::CODE_TO_OBJ[kind]
              when String, Symbol then Net.const_get("HTTP#{kind.to_s.camelize}") rescue Net::HTTPSuccess
            else
              Net::HTTPSuccess
            end
    @open_timeout = (open_timeout || 3).to_f
    @read_timeout = (read_timeout || timeout || 15).to_f
  end

  def get_value
    res = session.start{ |http| http.get(@uri.request_uri) }
    {:result => res}

  rescue Timeout::Error => ex
    debug { ex.inspect }

    if defined?(Net::OpenTimeout) # for ruby 2.0
      mes = ex.is_a?(Net::OpenTimeout) ? "OpenTimeout<#{@open_timeout}>" : "ReadTimeout<#{@read_timeout}>"
      {:exception => mes}
    else
      {:exception => "Timeout<#{@open_timeout},#{@read_timeout}>"}
    end

  rescue => ex
    {:exception => "Error<#{ex.message}>"}
  end

  def good?(value)
    return false unless value[:result]

    unless value[:result].kind_of?(@kind)
      return false
    end

    if pattern
      matched = if pattern.is_a?(Regexp)
        pattern === value[:result].body
      else
        value[:result].body.include?(pattern.to_s)
      end
      value[:notice] = "missing '#{pattern.to_s}'" unless matched
      matched
    else
      true
    end
  end

  def human_value(value)
    if !value.is_a?(Hash)
      '-'
    elsif value[:exception]
      value[:exception]
    else
      body_size = value[:result].body.size / 1024
      msg = "#{value[:result].code}=#{body_size}Kb"
      msg += "<#{value[:notice]}>" if value[:notice]
      msg
    end
  end

private

  def session
    Net::HTTP.new(@uri.host, @uri.port).tap do |session|
      if @uri.scheme == 'https'
        require 'net/https'
        session.use_ssl = true
        session.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end
      session.open_timeout = @open_timeout
      session.read_timeout = @read_timeout
    end
  end

end
