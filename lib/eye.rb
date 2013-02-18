module Eye  
  VERSION   = "0.1.11.d3"
  ABOUT     = "Eye v#{VERSION} (c) 2012-2013 @kostya"

  autoload :Process,        'eye/process'
  autoload :ChildProcess,   'eye/child_process'
  autoload :Server,         'eye/server'
  autoload :Logger,         'eye/logger'
  autoload :System,         'eye/system'
  autoload :SystemResources,'eye/system_resources'  
  autoload :Checker,        'eye/checker'
  autoload :Trigger,        'eye/trigger'
  autoload :Group,          'eye/group'
  autoload :Dsl,            'eye/dsl'  
  autoload :Application,    'eye/application'  
  autoload :Settings,       'eye/settings'
  autoload :Client,         'eye/client'
  autoload :Utils,          'eye/utils'
  
  autoload :Controller,     'eye/controller'
  autoload :Control,        'eye/control'
end

ROOT_BINDING  = binding
ENV_LANG      = ENV['LANG'] # save original LANG, because ruby somehow rewrite it
