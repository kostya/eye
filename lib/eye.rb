module Eye  
  VERSION   = "0.1.4"
  ABOUT     = "Eye v#{VERSION} (c) 2012 @kostya"

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
ENV_LANG      = ENV['LANG'] # save original LANG, because ruby somehow loose it
