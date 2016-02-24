require 'time'

def silence_warnings
  old_verbose, $VERBOSE = $VERBOSE, nil
  yield
ensure
  $VERBOSE = old_verbose
end

class Object
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end

  def present?
    !blank?
  end

  def try(m, *args)
    send(m, *args) if respond_to?(m)
  end
end

class NilClass
  def try(*args)
  end
end

class String
  def underscore
    word = self.dup
    word.gsub!('::', '/')
    word.gsub!(/(?:([A-Za-z\d])|^)((?=a)b)(?=\b|[^a-z])/) { "#{$1}#{$1 && '_'}#{$2.downcase}" }
    word.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
    word.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
    word.tr!('-', '_')
    word.downcase!
    word
  end
end

class Array
  def extract_options!
    self[-1].is_a?(Hash) ? self.pop : {}
  end
end

class Numeric
  def percents
    self
  end
  alias_method :percent, :percents

  def seconds
    self
  end
  alias_method :second, :seconds

  def minutes
    self * 60
  end
  alias_method :minute, :minutes

  def hours
    self * 3600
  end
  alias_method :hour, :hours

  def days
    self * 86_400
  end
  alias_method :day, :days

  def weeks
    self * 86_400 * 7
  end
  alias_method :week, :weeks

  def ago
    ::Time.now - self
  end

  def bytes
    self
  end
  alias_method :byte, :bytes

  def kilobytes
    self * 1024
  end
  alias_method :kilobyte, :kilobytes

  def megabytes
    self * 1024 * 1024
  end
  alias_method :megabyte, :megabytes

  def gigabytes
    self * 1024 * 1024 * 1024
  end
  alias_method :gigabyte, :gigabytes

  def terabytes
    self * 1024 * 1024 * 1024 * 1024
  end
  alias_method :terabyte, :terabytes
end
