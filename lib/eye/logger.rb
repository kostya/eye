require 'logger'

class Eye::Logger
  attr_accessor :prefix, :subprefix

  class InnerLogger < Logger
    def initialize(*args)
      super

      self.formatter = Proc.new do |s, d, p, m|
        "#{d.strftime("%d.%m.%Y %H:%M:%S")} #{s.ljust(5)} -- #{m}\n"
      end      
    end
  end

  module Helpers
    attr_accessor :logger

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
    attr_reader :dev
    attr_accessor :log_level

    def link_logger(dev)
      @dev = dev.to_s.downcase
      @dev_fd = @dev

      @dev_fd = STDOUT if @dev == 'stdout'
      @dev_fd = STDERR if @dev == 'stderr'
      
      @inner_logger = InnerLogger.new(@dev_fd)
      @inner_logger.level = self.log_level || Logger::INFO
    end

    def inner_logger
      @inner_logger ||= InnerLogger.new(nil)
    end
  end

private

  def prefix_str
    @pref_string ||= begin
      pref_string = ""

      if @prefix
        pref_string = "[#{@prefix}] "
        pref_string += "#{@subprefix} " if @subprefix
      end

      pref_string
    end
  end

end