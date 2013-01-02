require 'net/http'

class Eye::Checker::Http < Eye::Checker

  # ex: {:type => :http, :every => 5.seconds, :times => 1,
  #  :url => "http://localhost:3000/", :kind => :success, :pattern => /OK/, :timeout => 3.seconds

  params :url, :pattern, :kind, :timeout, :open_timeout, :read_timeout

  def check_name
    "http"
  end

  def initialize(*args)
    super

    @uri = URI.parse(url)
    @pattern = pattern
    @kind = case kind
              when Fixnum then Net::HTTPResponse::CODE_TO_OBJ[kind]
              when String, Symbol then Net.const_get("HTTP#{kind.to_s.camelize}") rescue Net::HTTPSuccess
            else
              Net::HTTPSuccess
            end
    @open_timeout = (open_timeout || timeout || 5).to_i
    @read_timeout = (read_timeout || timeout || 30).to_i

    @session = Net::HTTP.new(@uri.host, @uri.port)
    if @uri.scheme == 'https'
      require 'net/https'
      @session.use_ssl=true
      @session.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    @session.open_timeout = @open_timeout
    @session.read_timeout = @read_timeout
  end

  def get_value(pid)
    Eye::Utils.async_and_wait{ get_value_sync }
  end

  def get_value_sync
    res = @session.start do |http|
      http.get(@uri.path)
    end
    {:result => res}
  rescue Timeout::Error
    warn "Timeout error"
    {:exception => :timeout}
  rescue => ex
    warn "Exception #{ex.message}"
    {:exception => ex.message}
  end

  def good?(value)
    return false unless value[:result]
    return false unless value[:result].kind_of?(@kind)
    @pattern === value[:result].body
  end

  def human_value(value)
    if !value.is_a?(Hash)
      "-"
    elsif value[:exception]
      if value[:exception] == :timeout
        "T-out"
      else
        "Err"
      end
    else
      "#{value[:result].code}=#{value[:result].body.size/ 1024}Kb"
    end
  end

end