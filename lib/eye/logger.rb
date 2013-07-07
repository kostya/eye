require 'logger'

class Eye::Logger
  attr_accessor :prefix, :subprefix

  class InnerLogger < Logger
    FORMAT = '%d.%m.%Y %H:%M:%S'

    def initialize(*args)
      super

      self.formatter = Proc.new do |s, d, p, m|
        "#{d.strftime(FORMAT)} #{s.ljust(5)} -- #{m}\n"
      end
    end
  end

  module Helpers
    attr_reader :logger

    Logger::Severity.constants.each do |level|
      method_name = level.to_s.downcase
      define_method method_name do |msg|
        @logger.send(method_name, msg)
      end
    end
  end

  Logger::Severity.constants.each do |level|
    method_name = level.to_s.downcase
    define_method method_name do |msg|
      self.class.inner_logger.send(method_name, "#{prefix_str}#{msg}")
    end
  end

  def initialize(prefix = nil, subprefix = nil)
    @prefix = prefix
    @subprefix = subprefix
  end

  class << self
    attr_reader :dev, :log_level

    def link_logger(dev)
      @dev = dev ? dev.to_s : nil
      @dev_fd = @dev

      @dev_fd = STDOUT if @dev.to_s.downcase == 'stdout'
      @dev_fd = STDERR if @dev.to_s.downcase == 'stderr'

      @inner_logger = InnerLogger.new(@dev_fd)
      @inner_logger.level = self.log_level || Logger::INFO
    end

    def log_level=(level)
      @log_level = level
      @inner_logger.level = self.log_level if @inner_logger
    end

    def inner_logger
      @inner_logger ||= InnerLogger.new(nil)
    end
  end

private

  def prefix_str
    @pref_string ||= begin
      pref_string = ''

      if @prefix
        pref_string = "[#{@prefix}] "
        pref_string += "#{@subprefix} " if @subprefix
      end

      pref_string
    end
  end

end
