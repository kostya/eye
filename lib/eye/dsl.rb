require_relative 'dsl/helpers'

Eye::BINDING = binding

class Eye::Dsl

  autoload :Main,                 'eye/dsl/main'
  autoload :ApplicationOpts,      'eye/dsl/application_opts'
  autoload :GroupOpts,            'eye/dsl/group_opts'
  autoload :ProcessOpts,          'eye/dsl/process_opts'
  autoload :ChildProcessOpts,     'eye/dsl/child_process_opts'
  autoload :Opts,                 'eye/dsl/opts'
  autoload :PureOpts,             'eye/dsl/pure_opts'
  autoload :Validate,             'eye/dsl/validate'
  autoload :Chain,                'eye/dsl/chain'
  autoload :ConfigOpts,           'eye/dsl/config_opts'
  autoload :Validation,           'eye/dsl/validation'

  class Error < Exception; end
  extend Eye::Dsl::Validate

  class << self
    attr_accessor :verbose

    def debug(msg = "")
      puts msg if verbose
    end

    def initial_config
      {:config => {}, :applications => {}}
    end

    def parse(content = nil, filename = nil)
      Eye.parsed_config = initial_config
      Eye.parsed_filename = filename
      
      content = File.read(filename) if content.blank?
      
      silence_warnings do
        Kernel.eval(content, Eye::BINDING, filename.to_s)
      end
      
      validate(Eye.parsed_config)

      Eye.parsed_config
    end

    def parse_apps(*args)
      parse(*args)[:applications] || {}
    end
  end
end

# extend here global module
Eye.send(:extend, Eye::Dsl::Main)