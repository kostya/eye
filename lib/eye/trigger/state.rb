class Eye::Trigger::State < Eye::Trigger

  # triggers :state, :to => :up, :from => :starting, :do => ->{ ... }

  param :do, [Proc]

  def check(trans)
    instance_exec(&@options[:do]) if @options[:do]
  end

end
