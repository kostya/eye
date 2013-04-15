class Eye::Checker
  include Eye::Logger::Helpers

  autoload :Memory,     'eye/checker/memory'
  autoload :Cpu,        'eye/checker/cpu'
  autoload :Http,       'eye/checker/http'
  autoload :FileCTime,  'eye/checker/file_ctime'
  autoload :FileSize,   'eye/checker/file_size'
  autoload :Socket,     'eye/checker/socket'

  TYPES = {:memory => "Memory", :cpu => "Cpu", :http => "Http", 
           :ctime => "FileCTime", :fsize => "FileSize", :socket => "Socket"}

  attr_accessor :value, :values, :options, :pid, :type

  def self.get_class(type)
    klass = eval("Eye::Checker::#{TYPES[type]}") rescue nil
    raise "Unknown checker #{type}" unless klass
    klass
  end

  def self.create(pid, options = {}, logger_prefix = nil)
    get_class(options[:type]).new(pid, options, logger_prefix)
  end

  def self.validate!(options)
    get_class(options[:type]).validate(options)
  end

  def initialize(pid, options = {}, logger_prefix = nil)
    @pid = pid
    @options = options
    @type = options[:type]

    @logger = Eye::Logger.new(logger_prefix, "check:#{check_name}")
    debug "create checker, with #{options}"
    
    @value = nil
    @values = Eye::Utils::Tail.new(max_tries)
  end

  def last_human_values
    h_values = @values.map do |v| 
      sign = v[:good] ? '' : '*'
      sign + human_value(v[:value]).to_s
    end

    '[' + h_values * ', ' + ']'
  end

  def check
    @value = get_value
    @values << {:value => @value, :good => good?(value)}

    result = true

    if @values.size == max_tries
      bad_count = @values.count{|v| !v[:good] }
      result = false if bad_count >= min_tries
    end

    info "#{last_human_values} => #{result ? 'OK' : 'Fail'}"
    result
  end

  def get_value
    raise 'Realize me'
  end

  def human_value(value)
    value.to_s
  end

  # true if check ok
  # false if check bad
  def good?(value)
    raise 'Realize me'
  end

  def check_name
    @type.to_s
  end

  def max_tries
    @max_tries ||= if times
      if times.is_a?(Array)
        times[-1].to_i
      else
        times.to_i
      end
    else
      1
    end    
  end

  def min_tries
    @min_tries ||= if times
      if times.is_a?(Array)
        times[0].to_i
      else
        max_tries
      end
    else
      max_tries
    end
  end

  def previous_value
    @values[-1][:value] if @values.present?
  end

  extend Eye::Dsl::Validation
  param :every, [Fixnum, Float], false, 5
  param :times, [Fixnum, Array]
  param :fire, Symbol, nil, nil, [:stop, :restart, :unmonitor, :nothing]

  class Defer < Eye::Checker
    def get_value
      Celluloid::Future.new{ get_value_deferred }.value
    end
  end
end
