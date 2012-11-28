class Eye::Trigger
  # :triggers => [
  #   { :type => :flapping, :times => 2, :within => 30.seconds}
  # ],

  TYPES = [:flapping]

  autoload :Flapping,   'eye/trigger/flapping'

  include Eye::Logger::Helpers

  attr_reader :message, :options

  def self.create(options = {}, logger = nil)
    obj = case options[:type]
      when :flapping then Eye::Trigger::Flapping.new(options, logger)
    else
      raise "Unknown checker"
    end
  end

  def initialize(options = {}, logger = nil)
    @options = options
    prepare_logger(logger)

    debug "add trigger #{options}"
  end

  def check(states_history)
    @states_history = states_history

    res = good?

    if res
      debug "check flapping"
    else
      error "!!! #{self.class} recognized !!!"
    end
    
    res
  end

  def good?
    raise "realize me"
  end

  def self.params(*syms)
    syms.each { |s| define_method(s) { @options[s] } }
  end

end