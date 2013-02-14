class Eye::Dsl::ConfigOpts < Eye::Dsl::PureOpts

  create_options_methods([:logger], String)
  create_options_methods([:logger_level], Fixnum)
  create_options_methods([:http], Hash)
  
end