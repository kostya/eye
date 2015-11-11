class Eye::Trigger::Transition < Eye::Trigger

  # trigger :transition, :to => :up, :from => :starting, :do => ->{ ... }

  param :do, [Proc, Symbol]

  def check(_trans)
    exec_proc :do
  end

end
