class Eye::Checker
  include Eye::Dsl::Validation

  autoload :Memory,     'eye/checker/memory'
  autoload :Cpu,        'eye/checker/cpu'
  autoload :Http,       'eye/checker/http'
  autoload :FileCTime,  'eye/checker/file_ctime'
  autoload :FileSize,   'eye/checker/file_size'
  autoload :Socket,     'eye/checker/socket'
  autoload :Nop,        'eye/checker/nop'

  TYPES = {:memory => "Memory", :cpu => "Cpu", :http => "Http",
           :ctime => "FileCTime", :fsize => "FileSize", :socket => "Socket",
           :nop => "Nop" }

  attr_accessor :value, :values, :options, :pid, :type, :check_count, :process

  param :every, [Fixnum, Float], false, 5
  param :times, [Fixnum, Array], nil, 1
  param :fires, [Symbol, Array], nil, nil, [:stop, :restart, :unmonitor, :nothing, :start, :delete]
  param :initial_grace, [Fixnum, Float]

  def self.name_and_class(type)
    type = type.to_sym
    return {:name => type, :type => type} if TYPES[type]

    if type =~ /\A(.*?)_?[0-9]+\z/
      ctype = $1.to_sym
      return {:name => type, :type => ctype} if TYPES[ctype]
    end
  end

  def self.get_class(type)
    klass = eval("Eye::Checker::#{TYPES[type]}") rescue nil
    raise "Unknown checker #{type}" unless klass
    if deps = klass.depends_on
      Array(deps).each { |d| require d }
    end
    klass
  end

  def self.create(pid, options = {}, process = nil)
    get_class(options[:type]).new(pid, options, process)

  rescue Exception, Timeout::Error => ex
    log_ex(ex)
    nil
  end

  def self.validate!(options)
    get_class(options[:type]).validate(options)
  end

  def initialize(pid, options = {}, process = nil)
    @process = process
    @pid = pid
    @options = options
    @type = options[:type]
    @full_name = @process.full_name if @process
    @initialized_at = Time.now

    debug "create checker, with #{options}"

    @value = nil
    @values = Eye::Utils::Tail.new(max_tries)
    @check_count = 0
  end

  def inspect
    "<#{self.class} @process='#{@full_name}' @options=#{@options} @pid=#{@pid}>"
  end

  def logger_tag
    @process.logger.prefix
  end

  def logger_sub_tag
    "check:#{check_name}"
  end

  def last_human_values
    h_values = @values.map do |v|
      sign = v[:good] ? '' : '*'
      sign + human_value(v[:value]).to_s
    end

    '[' + h_values * ', ' + ']'
  end

  def check
    if initial_grace && !@initial_grace_skipped && (Time.now - @initialized_at < initial_grace)
      debug 'skipped initial grace'
      return true
    else
      @initial_grace_skipped = true
    end

    @value = get_value_safe
    @values << {:value => @value, :good => good?(value)}

    result = true
    @check_count += 1

    if @values.size == max_tries
      bad_count = @values.count{|v| !v[:good] }
      result = false if bad_count >= min_tries
    end

    info "#{last_human_values} => #{result ? 'OK' : 'Fail'}"
    result

  rescue Exception, Timeout::Error => ex
    log_ex(ex)
  end

  def get_value_safe
    get_value
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
    value
  end

  def check_name
    @check_name ||= @type.to_s
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

  def run_in_process_context(p)
    process.instance_exec(&p) if process.alive?
  end

  def defer(&block)
    Celluloid::Future.new(&block).value
  end

  class Defer < Eye::Checker
    def get_value_safe
      Celluloid::Future.new{ get_value }.value
    end
  end

  def self.register(base)
    name = base.to_s.gsub("Eye::Checker::", '')
    type = name.underscore.to_sym
    Eye::Checker::TYPES[type] = name
    Eye::Checker.const_set(name, base)
  end

  def self.depends_on
  end

  class CustomCell < Eye::Checker
    def self.inherited(base)
      super
      register(base)
    end
  end

  class Custom < Defer
    def self.inherited(base)
      super
      register(base)
    end
  end

  class CustomDefer < Defer
    def self.inherited(base)
      super
      register(base)
    end
  end
end
