# Hash with autocreated keys - as subhash
# h = MHash.new
# h[1][2][3] = 4
#  => {1 => {2 => {3 => 4}}}

class Eye::Utils::MHash < Hash
  def initialize
    super do |hash, key| 
      hash[key] = self.class.new(&hash.default_proc)
    end
  end

  def pure
    h = {}
    self.each do |k,v|
      if v.is_a?(Eye::Utils::MHash)
        h[k] = v.pure
      else
        h[k] = v
      end
    end
    h
  end

  def self.deep_clone(value)
    if value.is_a?(Hash)
      result = value.clone
      value.each{|k, v| result[k] = deep_clone(v)}
      result
    elsif value.is_a?(Array)
      result = value.clone
      result.clear
      value.each{|v| result << deep_clone(v)}
      result
    else
      value
    end  
  end

  def deep_clone
    self.class.deep_clone self
  end
end
