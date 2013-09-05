require 'date'

module Eye::Utils
  autoload :Tail,           'eye/utils/tail'
  autoload :AliveArray,     'eye/utils/alive_array'
  autoload :CelluloidChain, 'eye/utils/celluloid_chain'

  def self.deep_clone(value)
    case
      when value.is_a?(Array) then value.map{|v| deep_clone(v) }
      when value.is_a?(Hash) then value.inject({}){|r, (k, v)| r[ deep_clone(k) ] = deep_clone(v); r }
      else value
    end
  end

  D1 = '%H:%M'
  D2 = '%b%d'

  def self.human_time(unix_time)
    time = Time.at(unix_time.to_i)
    d1 = time.to_date
    d2 = Time.now.to_date
    time.strftime (d1 == d2) ? D1 : D2
  end

end
