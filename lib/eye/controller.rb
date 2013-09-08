require 'celluloid'

require 'yaml'
require 'active_support'
require 'active_support/core_ext/object/blank'
require 'active_support/core_ext/object/try'
require 'active_support/core_ext/numeric'
require 'active_support/core_ext/string/filters'
require 'active_support/core_ext/array/extract_options'

require_relative 'utils/celluloid_klass'
require_relative 'utils/pmap'

# Extend all objects with logger
Object.send(:include, Eye::Logger::ObjectExt)

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

  exclusive :load # load is hard command, so better to run it safely blocked

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

  def logger_tag
    'Eye'
  end

end
