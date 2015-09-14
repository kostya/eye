module Eye
  VERSION   = "0.8.pre"
  ABOUT     = "Eye v#{VERSION} (c) 2012-2015 @kostya"
  PROCLINE  = "eye monitoring v#{VERSION}"

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
  autoload :Local,          'eye/local'
  autoload :Client,         'eye/client'
  autoload :Utils,          'eye/utils'
  autoload :Notify,         'eye/notify'
  autoload :Config,         'eye/config'
  autoload :Reason,         'eye/reason'
  autoload :Sigar,          'eye/sigar'

  autoload :Controller,     'eye/controller'
  autoload :Control,        'eye/control'
  autoload :Cli,            'eye/cli'
end
