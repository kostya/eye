module Eye  
  VERSION = "0.1"

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
  autoload :Tail,           'eye/tail'
  autoload :Dsl,            'eye/dsl'  
  autoload :Application,    'eye/application'  
  autoload :Settings,       'eye/settings'

  class << self
    def controller
      @controller ||= Eye::Controller.new
    end    
  end
end

$root_binding = binding