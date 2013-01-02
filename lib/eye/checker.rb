class Eye::Checker
  autoload :Memory,   'eye/checker/memory'
  autoload :Cpu,      'eye/checker/cpu'
  autoload :Http,     'eye/checker/http'
  autoload :FileCTime,  'eye/checker/file_ctime'

  TYPES = [:memory, :cpu, :http, :ctime]

  include Eye::Logger::Helpers

  attr_accessor :value, :values, :options, :pid, :type

  def self.create(pid, options = {}, logger_prefix = nil)
    obj = case options[:type]
      when :memory then Eye::Checker::Memory.new(pid, options, logger_prefix)
      when :cpu then Eye::Checker::Cpu.new(pid, options, logger_prefix)
      when :http then Eye::Checker::Http.new(pid, options, logger_prefix)
      when :ctime then Eye::Checker::FileCTime.new(pid, options, logger_prefix)
    else
      raise "Unknown checker"
    end
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

    '[' + h_values * ", " + ']'
  end

  def check
    @value = get_value(@pid)
    @values << {:value => @value, :good => good?(value)}

    result = true

    if @values.size == max_tries
      bad_count = @values.count{|v| !v[:good] }
      result = false if bad_count >= min_tries
    end

    info "#{last_human_values} => #{result ? "OK" : "Fail"}"
    result
  end

  def get_value(pid)
    raise "Realize me"
  end

  def human_value(value)
    value.to_s
  end

  # true if check ok
  # false if check bad
  def good?(value)
    raise "Realize me"
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