class Eye::Trigger::StopChildren < Eye::Trigger

  # Kill process children when parent process crashed, or stopped:
  #
  # trigger :stop_children

  param :timeout, [Fixnum, Float], nil, 60

  # default on stopped, crashed
  param_default :event, [:stopped, :crashed]

  def check(trans)
    debug { 'stopping children' }
    process.children.pmap { |pid, c| c.stop }
  end

end
