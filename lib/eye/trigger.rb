class Eye::Trigger
  
  autoload :Flapping,   'eye/trigger/flapping'

  # ex: { :type => :flapping, :times => 2, :within => 30.seconds}

  TYPES = [:flapping]

  include Eye::Logger::Helpers

  attr_reader :message, :options

  def self.create(options = {}, logger_prefix = nil)
    obj = case options[:type]
      when :flapping then Eye::Trigger::Flapping.new(options, logger_prefix)
    else
      raise 'Unknown checker'
    end
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