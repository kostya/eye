require_relative 'dsl/helpers'

class Eye::Dsl

  autoload :Main,                 'eye/dsl/main'
  autoload :ApplicationOpts,      'eye/dsl/application_opts'
  autoload :GroupOpts,            'eye/dsl/group_opts'
  autoload :ProcessOpts,          'eye/dsl/process_opts'
  autoload :ChildProcessOpts,     'eye/dsl/child_process_opts'
  autoload :Opts,                 'eye/dsl/opts'
  autoload :Validate,             'eye/dsl/validate'
  autoload :Chain,                'eye/dsl/chain'

  def self.load(content = nil, filename = nil)
    Eye.parsed_config = {}
    Eye.parsed_options ||= {}
    Eye.parsed_filename = filename
    
    content = File.read(filename) if content.blank?
    
    Kernel.eval(content, ROOT_BINDING, filename.to_s)
    validate(Eye.parsed_config)

    Eye.parsed_config
  end

  extend Eye::Dsl::Validate

  class Error < Exception; end
end

# extend here global module
Eye.send(:extend, Eye::Dsl::Main)