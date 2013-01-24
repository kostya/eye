class Eye::Checker
  include Eye::Logger::Helpers

  autoload :Memory,     'eye/checker/memory'
  autoload :Cpu,        'eye/checker/cpu'
  autoload :Http,       'eye/checker/http'
  autoload :FileCTime,  'eye/checker/file_ctime'
  autoload :FileSize,   'eye/checker/file_size'

  TYPES = {:memory => "Memory", :cpu => "Cpu", :http => "Http", 
           :ctime => "FileCTime", :fsize => "FileSize"}

  attr_accessor :value, :values, :options, :pid, :type

  def self.create(pid, options = {}, logger_prefix = nil)
    type = options[:type]
    klass = eval("Eye::Checker::#{TYPES[type]}") rescue nil
    raise "Unknown checker #{type}" unless klass
    klass.new(pid, options, logger_prefix)
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
    self.class.to_s
  end

  def max_tries
    @max_tries ||= if @options[:times]
      if @options[:times].is_a?(Array)
        @options[:times][-1].to_i
      else
        @options[:times].to_i
      end
    else
      1
    end    
  end

  def min_tries
    @min_tries ||= if @options[:times]
      if @options[:times].is_a?(Array)
        @options[:times][0].to_i
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

  def self.params(*syms)
    syms.each { |s| define_method(s) { @options[s] } }
  end

end