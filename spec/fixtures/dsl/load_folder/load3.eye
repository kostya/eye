Eye.application "app3" do
  working_dir "/tmp"

  group("wow") {
    process "e1" do
      daemonize true
      pid_file "app3-e1.pid"
    end
  }
end