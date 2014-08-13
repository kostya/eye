class Eye::Trigger
  include Eye::Dsl::Validation

  autoload :Flapping,   'eye/trigger/flapping'
  autoload :Transition, 'eye/trigger/transition'
  autoload :StopChildren, 'eye/trigger/stop_children'
  autoload :WaitDependency, 'eye/trigger/wait_dependency'
  autoload :CheckDependency, 'eye/trigger/check_dependency'

  TYPES = {:flapping => 'Flapping', :transition => 'Transition', :stop_children => 'StopChildren',
    :wait_dependency => 'WaitDependency', :check_dependency => 'CheckDependency'
  }

  attr_reader :message, :options, :process

  def self.name_and_class(type)
    type = type.to_sym
    return {:name => type, :type => type} if TYPES[type]

    if type =~ /\A(.*?)_?[0-9]+\z/
      ctype = $1.to_sym
      return {:name => type, :type => ctype} if TYPES[ctype]
    end
  end

  def self.get_class(type)
    klass = eval("Eye::Trigger::#{TYPES[type]}") rescue nil
    raise "unknown trigger #{type}" unless klass
    if deps = klass.requires
      Array(deps).each { |d| require d }
    end
    klass
  end

  def self.create(process, options = {})
    get_class(options[:type]).new(process, options)

  rescue Exception, Timeout::Error => ex
    log_ex(ex)
    nil
  end

  def self.validate!(options = {})
    get_class(options[:type]).validate(options)
  end

  def initialize(process, options = {})
    @options = options
    @process = process
    @full_name = @process.full_name if @process

    debug { "add #{options}" }
  end

  def inspect
    "<#{self.class} @process='#{@full_name}' @options=#{@options}>"
  end

  def logger_tag
    @process.logger.prefix
  end

  def logger_sub_tag
    "trigger(#{@options[:type]})"
  end

  def notify(transition, reason)
    debug { "check (:#{transition.event}) :#{transition.from} => :#{transition.to}" }
    @reason = reason
    @transition = transition

    check(transition) if filter_transition(transition)

  rescue Exception, Timeout::Error => ex
    if ex.class == Eye::Process::StateError
      raise ex
    else
      log_ex(ex)
    end
  end

  param :to, [Symbol, Array]
  param :from, [Symbol, Array]
  param :event, [Symbol, Array]

  def filter_transition(trans)
    return true unless to || from || event

    compare_state(trans.to_name, to) &&
      compare_state(trans.from_name, from) &&
      compare_state(trans.event, event)
  end

  def check(transition)
    raise NotImplementedError
  end

  def run_in_process_context(p)
    process.instance_exec(&p) if process.alive?
  end

  def defer(&block)
    Celluloid::Future.new(&block).value
  end

  def self.register(base)
    name = base.to_s.gsub('Eye::Trigger::', '')
    type = name.underscore.to_sym
    Eye::Trigger::TYPES[type] = name
    Eye::Trigger.const_set(name, base)
  end

  def self.requires
  end

  class Custom < Eye::Trigger
    def self.inherited(base)
      super
      register(base)
    end
  end

private

  def compare_state(state_name, condition)
    case condition
    when Symbol
      state_name == condition
    when Array
      condition.include?(state_name)
    else
      true
    end
  end

end
