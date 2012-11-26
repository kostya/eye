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

  def self.load(content = "", filename = nil)
    Eye.temp_config = {}

    if content.blank?
      begin
        content = File.read(filename)
      rescue => ex
        raise Error.new(ex)
      end
    end

    Kernel.eval(content, $global_binding, filename.to_s)

    cfg = Eye.temp_config
    cfg = normalized_config(cfg)
    validate(cfg)

    Eye.temp_config = {}

    cfg 

  rescue NoMethodError => ex
    raise Error.new(ex)
  end

  class Error < Exception
  end

  extend Eye::Dsl::Validate
  extend Eye::Dsl::Normalize
end

Eye.send(:extend, Eye::Dsl::Main)
