class Eye::Utils::Tail < Array

  # limited array

  def initialize(max_size = 100)
    @max_size = max_size
    super()
  end

  def push(el)
    super(el)
    shift if length > @max_size
    self
  end

  def <<(el)
    push(el)
  end

end
