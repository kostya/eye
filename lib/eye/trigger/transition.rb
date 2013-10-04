class Eye::Trigger::Transition < Eye::Trigger

  # trigger :transition, :to => :up, :from => :starting, :do => ->{ ... }

  param :do, [Proc, Symbol]

  def check(trans)
    act = @options[:do]
    if act
      instance_exec(&@options[:do]) if act.is_a?(Proc)
      send(act, process) if act.is_a?(Symbol)
    end
  end

end
