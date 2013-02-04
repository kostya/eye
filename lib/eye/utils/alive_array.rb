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
    map{|x| x }
  end

  def full_size
    @arr.size
  end

  def pure
    @arr
  end

  def sort_by(&block)
    AliveArray.new super
  end

end