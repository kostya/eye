class Eye::Trigger::StopChildren < Eye::Trigger

  param :timeout, [Fixnum, Float], nil, 60

  def check(trans)
    debug 'stopping children'
    process.children.pmap { |pid, c| c.stop }
  end

end
