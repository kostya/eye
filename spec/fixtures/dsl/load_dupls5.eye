Eye.application "app1" do
  working_dir "/tmp"

  process("p1"){ pid_file "app1-p1.pid" }
  process("p2"){ pid_file "app1-p2.pid" }
  process("p3"){ pid_file "app1-p3.pid" }

  group :a do
    process("p1"){ pid_file "app1-a-p1.pid" }
    process("p2"){ pid_file "app1-a-p2.pid" }
  end

  group :b do
    process("p1"){ pid_file "app1-b-p1.pid" }
    process("p2"){ pid_file "app1-b-p2.pid" }
  end
end

Eye.application "app2" do
  process("p1"){ pid_file "app2-p1.pid" }
  process("p2"){ pid_file "app2-p2.pid" }
  process("p4"){ pid_file "app2-p4.pid" }
end

