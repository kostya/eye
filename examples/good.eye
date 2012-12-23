Eye.logger = "/tmp/1.log"

Eye.app("int") do
  working_dir File.expand_path(File.join(File.dirname(__FILE__), %w{ processes }))
  stdall "shlak.log"

  group "samples" do
    chain :grace => 5.seconds

    process("sample1") do
      pid_file "1.pid"
      start_command "ruby sample.rb"
      daemonize true
    end

    process("sample2") do
      pid_file "2.pid"
      start_command "ruby sample.rb -d --pid 2.pid --log shlak.log"
      checks :memory, :below => 300.megabytes, :times => 3
    end
  end

  process("forking") do
    pid_file "forking.pid"
    start_command "ruby forking.rb start"
    stop_command "ruby forking.rb stop"
    stdall "/tmp/2.log"
    stop_grace 5.seconds
  
    monitor_children do
      childs_update_period 5.seconds
      restart_command "kill -2 {{PID}}"
      checks :memory, :below => 300.megabytes, :times => 3
    end
  end

end
