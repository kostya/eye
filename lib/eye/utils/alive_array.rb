class AliveArray
  extend Forwardable
  include Enumerable

  def_delegators :@arr, :[], :<<, :clear, :delete, :size, :empty?

  def initialize(arr = [])
    @arr = arr
  end

  def each(&block)
    @arr.each{|elem| elem && elem.alive? && block[elem] }
  end

  def to_a
    @arr.map{|x| x}
  end

end