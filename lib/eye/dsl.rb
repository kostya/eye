require_relative 'dsl/helpers'

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

  class Error < Exception; end
  extend Eye::Dsl::Validate

  class << self
    attr_accessor :verbose

    def debug(msg = "")
      puts msg if verbose
    end

    def load(content = nil, filename = nil)
      Eye.parsed_config = {}
      Eye.parsed_options ||= {}
      Eye.parsed_filename = filename
      
      content = File.read(filename) if content.blank?
      
      Kernel.eval(content, ROOT_BINDING, filename.to_s)
      validate(Eye.parsed_config)

      Eye.parsed_config
    end
  end
end

# extend here global module
Eye.send(:extend, Eye::Dsl::Main)