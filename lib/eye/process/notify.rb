module Eye::Process::Notify

  # notify to user:
  # 1) process crushed by itself, and we restart it
  # 2) checker fire to restart process +
  # 3) flapping + switch to unmonitored

  # level = [:warn, :crit]

  # TODO: add mail, jabber here
  def notify(level, msg)
    warn "!!!!!!!! NOTIFY: #{level}, #{msg} !!!!!!!!!!!"
  end

end