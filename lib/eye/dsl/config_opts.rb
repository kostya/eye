class Eye::Dsl::ConfigOpts < Eye::Dsl::PureOpts

  create_options_methods([:logger], String)
  create_options_methods([:logger_level], Fixnum)
  create_options_methods([:http], Hash)

  def set_logger(logger)
    logger.blank? ? super('') : super
  end
  
end