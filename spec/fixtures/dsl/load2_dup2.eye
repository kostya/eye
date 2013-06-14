Eye.application "app1" do
  
  process "server_1" do
    working_dir "/tmp"
    pid_file "server.pid"
  end

  process "server_2" do
    working_dir "/tmp2"
    pid_file "server_2.pid"
  end

end