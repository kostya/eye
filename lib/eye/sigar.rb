require 'sigar'
require 'logger'

Eye::Sigar = ::Sigar.new
Eye::Sigar.logger = ::Logger.new(nil)
