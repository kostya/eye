Eye.load("./eye/*.rb") # load submodules
Eye.logger = "/tmp/eye.log" # eye logger
Eye.logger_level = Logger::DEBUG

Eye.app "test" do
  working_dir File.expand_path(File.join(File.dirname(__FILE__), %w[ processes ]))
  stdall "trash.log" # stdout + stderr
  env "APP_ENV" => "production"

  group "samples" do
    env "A" => "1" # env merging
    chain :grace => 5.seconds, :action => :restart # restarting with 5s interval, one by one.

    # eye daemonized process
    process("sample1") do
      pid_file "1.pid" # expanded with working_dir
      start_command "ruby ./sample.rb"
      daemonize true
      stdall "sample1.log"

      checks :cpu, :below => 30, :times => [3, 5]
    end

    # self daemonized process
    process("sample2") do
      pid_file "2.pid"
      start_command "ruby ./sample.rb -d --pid 2.pid --log sample2.log"
      stop_command "kill -9 {{PID}}"

      checks :memory, :below => 300.megabytes, :times => 3
    end
  end

  # daemon with 3 childs
  process("forking") do
    pid_file "forking.pid"
    start_command "ruby ./forking.rb start"
    stop_command "ruby forking.rb stop"
    stdall "forking.log"

    start_timeout 5.seconds
    stop_grace 5.seconds
  
    monitor_children do
      childs_update_period 5.seconds

      restart_command "kill -2 {{PID}}"
      checks :memory, :below => 300.megabytes, :times => 3
    end
  end

end
