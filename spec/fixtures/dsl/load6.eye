Eye.application "app1" do
  working_dir "/tmp"

  group "gr2" do
    chain :grace => 10.seconds
    process("p1"){ pid_file "app1-gr1-p1.pid" }
    process("p2"){ pid_file "app1-gr1-p2.pid" }
  end

  group "gr1" do
    process("q3"){ pid_file "app1-gr2-q3.pid" }
  end

  process("g4"){ pid_file "app1-g4.pid" }
  process("g5"){ pid_file "app1-g5.pid" }

end
