class Eye::Utils::AliveArray

  extend Forwardable
  include Enumerable

  def_delegators :@arr, :[], :<<, :clear, :delete, :size, :empty?, :push,
                 :flatten, :present?, :uniq!, :select!

  def initialize(arr = [])
    @arr = arr
  end

  def each(&block)
    @arr.each { |elem| elem && elem.alive? && block[elem] }
  end

  def to_a
    map { |x| x }
  end

  def full_size
    @arr.size
  end

  def pure
    @arr
  end

  def sort_by(&block)
    self.class.new super
  end

  def sort(&block)
    self.class.new super
  end

  def sort!
    @arr.sort!
  end

  def +(other)
    if other.is_a?(Eye::Utils::AliveArray)
      @arr += other.pure
    elsif other.is_a?(Array)
      @arr += other
    else
      raise "Unexpected + #{other}"
    end
    self
  end

  def ==(other)
    if other.is_a?(Eye::Utils::AliveArray)
      @arr == other.pure
    elsif other.is_a?(Array)
      @arr == other
    else
      raise "Unexpected == #{other}"
    end
  end

end
