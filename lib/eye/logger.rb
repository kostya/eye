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

  module ObjectExt
    def logger_tag
      [Class, Module].include?(self.class) ? to_s : "<#{self.class.to_s}>"
    end

    def logger_sub_tag
    end

    def logger
      @logger ||= Eye::Logger.new(logger_tag, logger_sub_tag)
    end

    Logger::Severity.constants.each do |level|
      method_name = level.to_s.downcase
      define_method method_name do |msg = nil, &block|
        logger.send(method_name, msg, &block)
      end
    end

    def log_ex(ex)
      error "#{ex.message} #{ex.backtrace}"
      # notify here?
    end
  end

  Logger::Severity.constants.each do |level|
    method_name = level.to_s.downcase
    define_method method_name do |msg = nil, &block|
      if block
        self.class.inner_logger.send(method_name) { "#{prefix_str}#{block.call}" }
      else
        self.class.inner_logger.send(method_name, "#{prefix_str}#{msg}")
      end
    end
  end

  def initialize(prefix = nil, subprefix = nil)
    @prefix = prefix
    @subprefix = subprefix
  end

  class << self
    attr_reader :dev, :log_level, :args

    def link_logger(dev, *args)
      old_dev = @dev
      @dev = @dev_fd = dev
      @args = args

      if dev.nil?
        @inner_logger = InnerLogger.new(nil)
      elsif dev.is_a?(String)
        @dev_fd = STDOUT if @dev.to_s.downcase == 'stdout'
        @dev_fd = STDERR if @dev.to_s.downcase == 'stderr'
        @inner_logger = InnerLogger.new(@dev_fd, *args)
      else
        @inner_logger = dev
      end

      @inner_logger.level = self.log_level || Logger::INFO

    rescue Exception
      @inner_logger = nil
      @dev = old_dev
      raise
    end

    def reopen
      link_logger(dev, *args)
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
