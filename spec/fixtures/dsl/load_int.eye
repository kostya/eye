Eye.application "app1" do
  group "gr1" do
    process("p1"){ pid_file "app1-gr1-p1.pid" }
    process("p2"){ pid_file "app1-gr1-p2.pid" }
  end

  process("p0"){ pid_file "app1-p0.pid" }
end
