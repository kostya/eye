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
  autoload :Chain,                'eye/dsl/chain'
  autoload :ConfigOpts,           'eye/dsl/config_opts'
  autoload :Validation,           'eye/dsl/validation'

  class Error < Exception; end

  class << self
    attr_accessor :verbose

    def debug(msg = '')
      puts msg if verbose
    end

    def parse(content = nil, filename = nil)
      Eye.parsed_config = Eye::Config.new
      Eye.parsed_filename = filename
      Eye.parsed_default_app = nil

      content = File.read(filename) if content.blank?

      silence_warnings do
        Kernel.eval(content, Eye::BINDING, filename.to_s)
      end

      Eye.parsed_config.validate!(false)
      Eye.parsed_config
    end

    def parse_apps(*args)
      parse(*args).applications
    end

    def check_name(name)
      raise Error, "':' is not allowed in name '#{name}'" if name.to_s.include?(':')
    end
  end
end

# extend here global module
Eye.send(:extend, Eye::Dsl::Main)
