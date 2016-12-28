require 'date'

module Eye::Utils

  autoload :Tail,           'eye/utils/tail'
  autoload :AliveArray,     'eye/utils/alive_array'

  def self.deep_clone(value)
    if value.is_a?(Array)
      value.map { |v| deep_clone(v) }
    elsif value.is_a?(Hash)
      value.each_with_object({}) { |(k, v), r| r[deep_clone(k)] = deep_clone(v) }
    else
      value
    end
  end

  # deep merging b into a (a deeply changed)
  def self.deep_merge!(a, b, allowed_keys = nil)
    b.each do |k, v|
      next if allowed_keys && !allowed_keys.include?(k)
      if a[k].is_a?(Hash) && v.is_a?(Hash)
        deep_merge!(a[k], v)
      else
        a[k] = v
      end
    end
    a
  end

  D1 = '%H:%M'.freeze
  D2 = '%b%d'.freeze

  def self.human_time(unix_time)
    time = Time.at(unix_time.to_i)
    d1 = time.to_date
    d2 = Time.now.to_date
    time.strftime(d1 == d2 ? D1 : D2)
  end

  DF = '%d %b %H:%M'.freeze

  def self.human_time2(unix_time)
    Time.at(unix_time.to_i).strftime(DF)
  end

  def self.load_env(filename)
    content = File.read(filename)
    env_vars = content.split("\n")
    h = {}
    env_vars.each do |e|
      e = e.gsub(%r[#.+$], '').strip
      next unless e.include?('=')
      k, v = e.split('=', 2)
      h[k] = v.gsub(%r/^["']+(.*)["']+$/, '\1')
    end
    h
  end

  def self.wait_signal(timeout = nil, &block)
    signal = Celluloid::Condition.new
    block.call(signal)
    signal.wait((timeout || 600).to_f)
    :ok
  rescue Celluloid::ConditionError
    :timeouted
  end

end
