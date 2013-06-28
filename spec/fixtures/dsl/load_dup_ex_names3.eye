Eye.application "app1" do

  group "gr" do
    process "server" do
      pid_file "server2.pid"
    end
  end
end

Eye.application "app2" do

  group "gr" do
    process "server" do
      pid_file "server2.pid"
    end
  end
end