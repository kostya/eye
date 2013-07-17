require 'celluloid'

require 'yaml'
require 'active_support'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/numeric'
require 'active_support/core_ext/string/filters'

require_relative 'utils/celluloid_klass'

# Extend all objects with logger
Object.send(:include, Eye::Logger::ObjectExt)

class Eye::Controller
  include Celluloid

  autoload :Load,           'eye/controller/load'
  autoload :Helpers,        'eye/controller/helpers'
  autoload :Commands,       'eye/controller/commands'
  autoload :Status,         'eye/controller/status'
  autoload :SendCommand,    'eye/controller/send_command'
  autoload :ShowHistory,    'eye/controller/show_history'
  autoload :Options,        'eye/controller/options'

  include Eye::Controller::Load
  include Eye::Controller::Helpers
  include Eye::Controller::Commands
  include Eye::Controller::Status
  include Eye::Controller::SendCommand
  include Eye::Controller::ShowHistory
  include Eye::Controller::Options

  attr_reader :applications, :current_config

  def initialize
    @applications = []
    @current_config = Eye::Config.new

    Celluloid::logger = Eye::Logger.new('celluloid')
    Eye::SystemResources.setup

    info "starting #{Eye::ABOUT} (#{$$})"
  end

  def settings
    current_config.settings
  end

end
