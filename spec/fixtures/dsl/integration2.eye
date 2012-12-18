# different from integration.eye, with names of the processes

Eye.app("int") do
  working_dir File.join(File.dirname(__FILE__), %w{.. .. example})
  stdall "shlak.log"

  group "samples" do
    process("sample1_") do
      pid_file "1.pid"
      start_command "ruby sample.rb"
      daemonize true
    end

    process("sample2_") do
      pid_file "2.pid"
      start_command "ruby sample.rb -d --pid 2.pid --log shlak.log"
      checks :memory, :below => 300.megabytes
    end
  end

  process("forking") do
    pid_file "forking.pid"
    start_command "ruby forking.rb start"
    stop_command "ruby forking.rb stop"

    monitor_children do
      childs_update_period 5.seconds
      restart_command "kill -2 {{PID}}"
    end
  end

end