require 'celluloid/current'
require 'yaml'

require_relative 'utils/pmap'
require_relative 'utils/mini_active_support'

# Extend all objects with logger
Object.send(:include, Eye::Logger::ObjectExt)

# needs to preload
Eye::Sigar
Eye::SystemResources

class Eye::Controller

  include Celluloid

  autoload :Load,           'eye/controller/load'
  autoload :Helpers,        'eye/controller/helpers'
  autoload :Commands,       'eye/controller/commands'
  autoload :Status,         'eye/controller/status'
  autoload :Apply,          'eye/controller/apply'
  autoload :Options,        'eye/controller/options'

  include Eye::Controller::Load
  include Eye::Controller::Helpers
  include Eye::Controller::Commands
  include Eye::Controller::Status
  include Eye::Controller::Apply
  include Eye::Controller::Options

  attr_reader :applications, :current_config

  def initialize
    @applications = []
    @current_config = Eye::Config.new

    Celluloid.logger = Eye::Logger.new('celluloid')

    info "starting #{Eye::ABOUT} <#{$$}>"
  end

  def settings
    current_config.settings
  end

  def logger_tag
    'Eye'
  end

end
