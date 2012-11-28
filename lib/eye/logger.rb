require 'logger'

class Eye::Logger < Logger
  attr_accessor :prefix

  module Helpers
    attr_accessor :logger

    Logger::Severity.constants.each do |level|
      method_name = level.to_s.downcase
      define_method(method_name) do |message|
        @logger.send(method_name, "#{message}")
      end
    end

    def prepare_logger(logger, prefix = nil)
      @logger = logger ? logger.with_prefix(prefix || logger.prefix) : Eye::Logger.new(nil)
    end
  end

  def format(s, d, p, m)
    if prefix
      "#{d.strftime("%d.%m.%Y %H:%M:%S")} #{s.ljust(5)} -- [#{prefix}] #{m}\n "
    else
      "#{d.strftime("%d.%m.%Y %H:%M:%S")} #{s.ljust(5)} -- #{m}\n "
    end
  end

  def initialize(*a)
    @initial_args = a
    super
    self.formatter = method(:format).to_proc
    self.level = Logger::DEBUG
    @prefix = nil
  end

  def with_prefix(prefix)
    old = self
    self.class.new(*@initial_args).tap{|l|
      l.formatter = l.method(:format).to_proc
      l.prefix = prefix 
      l.level = old.level
    }
  end

end