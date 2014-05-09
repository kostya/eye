Eye.load('./plugin.rb')

Eye.config do
  logger "/tmp/eye.log"
  enable_reactor(1.second, "/tmp/cmd.txt")
  enable_saver("/tmp/saver.log")
end

Eye.app :app do
  process :process do
    pid_file "/tmp/p.pid"
    start_command "sleep 10"
    daemonize true
  end
end
