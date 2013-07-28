class Eye::Trigger::State < Eye::Trigger

  # triggers :state, :to => :up, :from => :starting, :do => ->{ ... }

  param :to, [Symbol]
  param :from, [Symbol]
  param :event, [Symbol]
  param :do, [Proc]

  def check(transition)
    if (to && transition.to_name == to) ||
        (from && from == transition.from_name) ||
        (event && transition.event == event)
      @options[:do].call if @options[:do]
    end
  end

end
