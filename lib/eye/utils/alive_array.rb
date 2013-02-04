class AliveArray
  extend Forwardable
  include Enumerable

  def_delegators :@arr, :[], :<<, :clear, :delete, :size, :empty?
  attr_reader :arr

  def initialize(arr = [])
    @arr = arr
  end

  def each(&block)
    @arr.each{|elem| elem && elem.alive? && block[elem] }
  end

  def to_a
    map{|x| x }
  end

end