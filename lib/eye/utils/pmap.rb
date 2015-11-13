module Enumerable

  # Simple parallel map using Celluloid::Futures
  def pmap(&block)
    map { |elem| Celluloid::Future.new(elem, &block) }.map(&:value)
  end

end
