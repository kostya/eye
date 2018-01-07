# This example shows how to write custom checks:
#   We check process procline every 1.second, and if it matches `haha`
#   send TERM signal

class MyCheck < Eye::Checker::Custom

  def get_value
    Eye::SystemResources.args(@pid)
  end

  def good?(value)
    value !~ /haha/
  end

end

Eye.app :bla do
  process :a do
    start_command "ruby -e 'sleep 10; $0 = %{HAHA}.downcase; sleep'"
    daemonize true
    pid_file '/tmp/1.pid'
    check :my_check, every: 1.second, fires: -> { send_signal(:TERM) }
  end
end
