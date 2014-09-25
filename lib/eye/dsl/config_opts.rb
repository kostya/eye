class Eye::Dsl::ConfigOpts < Eye::Dsl::PureOpts

  create_options_methods([:logger_level], Fixnum)
  create_options_methods([:http], Hash)

  def logger(*args)
    if args.empty?
      @config[:logger]
    else
      @config[:logger] = args
    end
  end
  alias logger= logger

  # ==== contact options ==============================
  def self.add_notify(type)
    create_options_methods([type], Hash)

    define_method("set_#{type}") do |value|
      value = value.merge(:type => type)
      super(value)
      Eye::Notify.validate!(value)
    end
  end

  Eye::Notify::TYPES.keys.each { |name| add_notify(name) }

  def contact(contact_name, contact_type, contact, contact_opts = {})
    raise Eye::Dsl::Error, "unknown contact_type #{contact_type}" unless Eye::Notify::TYPES[contact_type]
    raise Eye::Dsl::Error, 'contact should be a String' unless contact.is_a?(String)

    notify_hash = @config[contact_type] || (@parent && @parent.config[contact_type]) || Eye::parsed_config.settings[contact_type] || {}
    validate_hash = notify_hash.merge(contact_opts).merge(:type => contact_type)

    Eye::Notify.validate!(validate_hash)

    @config[:contacts] ||= {}
    @config[:contacts][contact_name.to_s] = {name: contact_name.to_s, type: contact_type,
      contact: contact, opts: contact_opts}
  end

  def contact_group(contact_group_name, &block)
    c = Eye::Dsl::ConfigOpts.new nil, self, false
    c.instance_eval(&block)
    cfg = c.config
    @config[:contacts] ||= {}
    if cfg[:contacts].present?
      @config[:contacts][contact_group_name.to_s] = cfg[:contacts].values
      @config[:contacts].merge!(cfg[:contacts])
    end
  end

end
