require 'logger'

class Eye::Logger < Logger

  def initialize(*a)
    super

    @tag = ""
    self.formatter = lambda do |s, d, p, m| 
      "#{d.strftime("%d.%m.%Y %H:%M:%S")} #{s} [#{@tag}] #{m}\n "
    end
    self.level = Logger::DEBUG
  end

  def tag
    @tag
  end

  def tag=(tag)
    @tag = tag
  end

  def attach()
  end

end
