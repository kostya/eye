class Eye::Trigger::State < Eye::Trigger

  # triggers :state, :to => :up, :from => :starting, :do => ->{ ... }

  param :to, [Symbol, Array]
  param :from, [Symbol, Array]
  param :event, [Symbol, Array]
  param :do, [Proc]

  def check(trans)
    if compare(trans.to_name, to) || compare(trans.from_name, from) || compare(trans.event, event)
      @options[:do].call if @options[:do]
    end
  end

private

  def compare(state_name, condition)
    case condition
    when Symbol
      state_name == condition
    when Array
      condition.include?(state_name)
    end
  end

end
