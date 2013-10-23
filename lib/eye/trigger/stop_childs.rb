class Eye::Trigger::StopChilds < Eye::Trigger

  param :timeout, [Fixnum, Float], nil, 60

  def check(trans)
    debug 'stop childs'
    process.childs.pmap { |pid, c| c.stop }
  end

end
