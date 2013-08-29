class Eye::Trigger::State < Eye::Trigger

  # triggers :state, :to => :up, :from => :starting, :do => ->{ ... }

  param :do, [Proc]

  def check(trans)
    @options[:do].call if @options[:do]
  end

end
