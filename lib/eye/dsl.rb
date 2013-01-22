require_relative 'dsl/helpers'

class Eye::Dsl

  autoload :Main,                 'eye/dsl/main'
  autoload :Normalize,            'eye/dsl/normalize'
  autoload :ApplicationOpts,      'eye/dsl/application_opts'
  autoload :GroupOpts,            'eye/dsl/group_opts'
  autoload :ProcessOpts,          'eye/dsl/process_opts'
  autoload :ChildProcessOpts,     'eye/dsl/child_process_opts'
  autoload :Opts,                 'eye/dsl/opts'
  autoload :Validate,             'eye/dsl/validate'
  autoload :Chain,                'eye/dsl/chain'

  def self.load(content = nil, filename = nil)
    Eye.parsed_config = {}
    Eye.parsed_options = {}
    Eye.parsed_filename = filename
    
    content = File.read(filename) if content.blank?
    
    Kernel.eval(content, ROOT_BINDING, filename.to_s)

    cfg = Eye.parsed_config
    cfg = normalized_config(cfg)
    validate(cfg)

    cfg 
  end

  extend Eye::Dsl::Validate
  extend Eye::Dsl::Normalize

  class Error < Exception; end
end

# extend here global module
Eye.send(:extend, Eye::Dsl::Main)