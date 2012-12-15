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
end
