class Eye::Trigger
  include Eye::Logger::Helpers
  
  autoload :Flapping,   'eye/trigger/flapping'

  # ex: { :type => :flapping, :times => 2, :within => 30.seconds}

  TYPES = {:flapping => "Flapping"}

  attr_reader :message, :options

  def self.create(options = {}, logger_prefix = nil)
    type = options[:type]
    klass = eval("Eye::Trigger::#{TYPES[type]}") rescue nil
    raise "Unknown trigger #{type}" unless klass
    klass.new(options, logger_prefix)
  end

  def initialize(options = {}, logger_prefix = nil)
    @options = options
    @logger = Eye::Logger.new(logger_prefix, "trigger")

    debug "add trigger #{options}"
  end

  def check(states_history)
    @states_history = states_history

    res = good?

    if res
      debug 'check flapping'
    else
      debug "!!! #{self.class} recognized !!!"
    end
    
    res
  end

  def good?
    raise 'realize me'
  end

  def self.params(*syms)
    syms.each { |s| define_method(s) { @options[s] } }
  end

end