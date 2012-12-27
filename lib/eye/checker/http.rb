require 'net/http'

class Eye::Checker::Http < Eye::Checker

  # ex: {:type => :http, :every => 5.seconds, :times => 1,
  #  :url => "http://localhost:3000/", :kind => :success, :pattern => /OK/, :timeout => 3.seconds

  def check_name
    "http"
  end

  def initialize(*args)
    super

    @uri = URI.parse(options[:url])
    @pattern = options[:pattern]
    @kind = case options[:kind]
              when Fixnum then Net::HTTPResponse::CODE_TO_OBJ[options[:kind].to_s]
              when String, Symbol then Net.const_get("HTTP#{options[:kind].to_s.camelize}") rescue Net::HTTPSuccess
            else
              Net::HTTPSuccess
            end
    @open_timeout = (options[:open_timeout] || options[:timeout] || 5).to_i
    @read_timeout = (options[:read_timeout] || options[:timeout] || 30).to_i

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