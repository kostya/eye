Eye.application "app1" do

  group "p2" do
    process "server" do
      pid_file "server2.pid"
    end
  end

  group "p1" do
    process "server" do
      pid_file "server1.pid"
    end
  end

end