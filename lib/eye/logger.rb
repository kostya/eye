require 'logger'

class Eye::Logger < Logger
  attr_accessor :prefix, :subprefix

  module Helpers
    attr_accessor :logger

    Logger::Severity.constants.each do |level|
      method_name = level.to_s.downcase
      define_method(method_name) do |message|
        @logger.send(method_name, "#{message}")
      end
    end

    def prepare_logger(logger, prefix = nil, subprefix = nil)
      @logger = if logger
        logger.with_prefix(prefix || logger.prefix, subprefix || logger.subprefix)
      else
        Eye::Logger.new(nil)
      end
    end
  end

  def format(s, d, p, m)
    if prefix
      pref_string = "[#{prefix}]"
      if subprefix
        pref_string += " #{subprefix}"
      end
    end

    "#{d.strftime("%d.%m.%Y %H:%M:%S")} #{s.ljust(5)} -- #{pref_string} #{m}\n "
  end

  def initialize(*a)
    @initial_args = a
    super
    self.formatter = method(:format).to_proc
    self.level = Logger::DEBUG
    @prefix = nil
  end

  def with_prefix(prefix, subprefix = nil)
    old = self
    self.class.new(*@initial_args).tap{|l|
      l.formatter = l.method(:format).to_proc
      l.prefix = prefix 
      l.subprefix = subprefix 
      l.level = old.level
    }
  end

end