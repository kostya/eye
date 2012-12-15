require 'celluloid'

class Eye::Utils::WithActor
  include Celluloid

  def with(&block)
    block.call
  end
end