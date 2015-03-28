class Eye::Reason

  def initialize(mes = nil)
    @message = mes
  end

  def to_s
    @message.to_s
  end

  def user?
    self.class == User
  end

  class User < Eye::Reason
    def to_s
      "#{super} by user"
    end
  end

  class Flapping < Eye::Reason; end
  class StartingGuard < Eye::Reason; end
end