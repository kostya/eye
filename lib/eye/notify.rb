class Eye::Notify
  include Celluloid
  include Eye::Logger::Helpers
  extend Eye::Checker::Validation

  autoload :Mail,     'eye/notify/mail'
  autoload :Jabber,   'eye/notify/jabber'

  TYPES = {:mail => "Mail", :jabber => "Jabber"}

  def self.get_class(type)
    klass = eval("Eye::Notify::#{TYPES[type]}") rescue nil
    raise "Unknown notify #{type}" unless klass
    klass
  end

  def self.validate!(options)
    get_class(options[:type]).validate(options)
  end

  def self.notify(contact, message_h)
    current_config = Eye::Control.current_config[:config] # Warning, using global reference here !!! (not so nice)
    needed_hash = (current_config[:contacts] || {})[contact.to_s]

    return if needed_hash.blank?

    create_proc = lambda do |nh|
      type = nh[:type]
      config = (current_config[type] || {}).merge(nh[:opts] || {}).merge(:contact => nh[:contact])
      get_class(type).new(config, message_h)
    end

    if needed_hash.is_a?(Array)
      needed_hash.each{|nh| create_proc[nh] }
    else
      create_proc[needed_hash]
    end
  end

  TIMEOUT = 1.minute

  def initialize(options = {}, message_h = {})
    @logger = Eye::Logger.new(self.class.name.downcase)
    debug "created notifier #{options}"

    @message_h = message_h
    @message = @message_h[:message]
    @options = options
    async.notify
    after(TIMEOUT){ terminate }
  end

  def notify
    debug "start notify #{@message}"
    execute
    debug "end notify #{@message}"
    terminate
  end

  def execute
    raise "realize me"
  end

  param :contact, [String]

private

  def subject
    "[#{Eye::System.host}] #{@msg.truncate(30)}"
  end
  
  def message
    "[#{Eye::System.host}] #{@msg} at #{Time.now.to_s(:short)}"
  end

end