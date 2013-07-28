class Eye::Trigger
  autoload :Flapping,   'eye/trigger/flapping'

  # ex: { :type => :flapping, :times => 2, :within => 30.seconds}

  TYPES = {:flapping => "Flapping"}

  attr_reader :message, :options, :process

  def self.get_class(type)
    klass = eval("Eye::Trigger::#{TYPES[type]}") rescue nil
    raise "Unknown trigger #{type}" unless klass
    klass
  end

  def self.create(process, options = {})
    get_class(options[:type]).new(process, options)
  end

  def self.validate!(options = {})
    get_class(options[:type]).validate(options)
  end

  def initialize(process, options = {})
    @options = options
    @process = process

    debug "add #{options}"
  end

  def logger_tag
    @process.logger.prefix
  end

  def logger_sub_tag
    "trigger(#{@options[:type]})"
  end

  def notify(transition)
    debug "check"
    check(transition)
  end

  def check(transition)
    raise "realize me"
  end

  extend Eye::Dsl::Validation

end