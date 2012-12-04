require 'celluloid'
require 'active_support'
require 'active_support/time'
require 'active_support/core_ext'
require 'ostruct'

class Eye::Controller
  include Celluloid

  autoload :Load,     'eye/controller/load'
  autoload :Helpers,  'eye/controller/helpers'
  autoload :Commands, 'eye/controller/commands'

  include Eye::Logger::Helpers
  include Eye::Controller::Load
  include Eye::Controller::Helpers
  include Eye::Controller::Commands

  attr_reader :applications, :current_config

  def initialize(logger = nil)
    @logger = logger || Eye::Logger.new(STDOUT)    
    @applications = []
    @current_config = {}

    Celluloid::logger = @logger
  end

end