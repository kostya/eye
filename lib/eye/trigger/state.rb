class Eye::Trigger::State < Eye::Trigger

  # triggers :state, :to => :up, :from => :starting, :do => ->{ ... }

  param :do, [Proc]

  def check(trans)
    run_in_process_context(@options[:do]) if @options[:do]
  end

end
