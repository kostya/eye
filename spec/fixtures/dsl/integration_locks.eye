Eye.app("int") do
  working_dir File.join(File.dirname(__FILE__), %w{.. .. example})
  stdall "shlak.log"

  group "samples" do
    process("sample1") do
      pid_file "1.pid"
      start_command "ruby sample.rb -L lock1.lock"
      daemonize true
    end

    process("sample2") do
      pid_file "2.pid"
      start_command "ruby sample.rb -d --pid 2.pid --log shlak.log -L lock2.lock"
      checks :memory, :below => 300.megabytes
    end
  end

  process("forking") do
    pid_file "forking.pid"
    start_command "ruby forking.rb start"
    stop_command "ruby forking.rb stop"

    monitor_children do
      children_update_period 5.seconds
      restart_command "kill -2 {PID}"
    end
  end

end
