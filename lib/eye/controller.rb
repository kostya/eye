require 'celluloid'
require 'yaml'

require_relative 'utils/celluloid_klass'
require_relative 'utils/pmap'

require_relative 'utils/leak_19'
require_relative 'utils/mini_active_support'

# Extend all objects with logger
Object.send(:include, Eye::Logger::ObjectExt)

Eye::Sigar # needs to preload

class Eye::Controller
  include Celluloid

  autoload :Load,           'eye/controller/load'
  autoload :Helpers,        'eye/controller/helpers'
  autoload :Commands,       'eye/controller/commands'
  autoload :Status,         'eye/controller/status'
  autoload :SendCommand,    'eye/controller/send_command'
  autoload :Options,        'eye/controller/options'

  include Eye::Controller::Load
  include Eye::Controller::Helpers
  include Eye::Controller::Commands
  include Eye::Controller::Status
  include Eye::Controller::SendCommand
  include Eye::Controller::Options

  attr_reader :applications, :current_config

  def initialize
    @applications = []
    @current_config = Eye::Config.new

    Celluloid::logger = Eye::Logger.new('celluloid')
    Eye::SystemResources.cache

    info "starting #{Eye::ABOUT} <#{$$}>"
  end

  def settings
    current_config.settings
  end

  def logger_tag
    'Eye'
  end

end
