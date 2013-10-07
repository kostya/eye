Eye.application "app1" do
  working_dir "/tmp"

  process("a1"){ pid_file "app1-a1.pid" }

  group "admin" do
    process("e1"){ pid_file "app1-p1.pid" }
    process("e3"){ pid_file "app1-p3.pid" }
  end

  group(:zoo){}
end

Eye.application "app2" do
  working_dir "/tmp"

  process("a2"){ pid_file "app2-a2.pid" }

  group "admin" do
    process("e1"){ pid_file "app2-p1.pid" }
    process("e2"){ pid_file "app2-p2.pid" }
  end

  process("zoo"){ pid_file "app2-zoo.pid" }

  group(:koo){
    process("koo"){ pid_file "app2-koo.pid" }
  }

  process("p1"){ pid_file "app2-pp1.pid" }
end

