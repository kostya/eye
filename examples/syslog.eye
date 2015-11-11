# output eye logger to syslog, and process stdout to syslog too
#   experimental feature, in some cases may be unstable

Eye.config do
  logger syslog
end

Eye.app :syslog_test do
  process :some do
    pid_file '/tmp/syslog_test.pid'
    start_command "ruby -e 'loop { p Time.now; sleep 1 }'"
    daemonize!
    stdall syslog
  end
end
