module Eye  
  VERSION = "0.1.1"

  autoload :Process,        'eye/process'
  autoload :ChildProcess,   'eye/child_process'
  autoload :Server,         'eye/server'
  autoload :Logger,         'eye/logger'
  autoload :System,         'eye/system'
  autoload :SystemResources,'eye/system_resources'
  autoload :Controller,     'eye/controller'
  autoload :Checker,        'eye/checker'
  autoload :Trigger,        'eye/trigger'
  autoload :Group,          'eye/group'
  autoload :Dsl,            'eye/dsl'  
  autoload :Application,    'eye/application'  
  autoload :Settings,       'eye/settings'
  autoload :Client,         'eye/client'
  autoload :Utils,          'eye/utils'

  class << self
    def controller
      @controller ||= Eye::Controller.new
    end    
  end
end

ROOT_BINDING  = binding
ENV_LANG      = ENV['LANG'] # save original LANG, because ruby somehow loose it