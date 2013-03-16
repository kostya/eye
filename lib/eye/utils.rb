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

end
