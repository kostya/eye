Eye.load("./eye/*.rb") # load submodules

Eye.config do
  logger "/tmp/eye.log" # eye logger
  logger_level Logger::DEBUG
end

Eye.application "test" do
  working_dir File.expand_path(File.join(File.dirname(__FILE__), %w[ processes ]))
  stdall "trash.log" # logs for processes by default
  env "APP_ENV" => "production" # global env for each processes
  triggers :flapping, :times => 10, :within => 1.minute
  stop_on_delete true # process will stopped before delete

  group "samples" do
    env "A" => "1" # merging to app env 
    chain :grace => 5.seconds, :action => :restart # restarting with 5s interval, one by one.

    # eye daemonized process
    process("sample1") do
      pid_file "1.pid" # will be expanded with working_dir
      start_command "ruby ./sample.rb"
      daemonize true
      stdall "sample1.log"

      checks :cpu, :below => 30, :times => [3, 5]
    end

    # self daemonized process
    process("sample2") do
      pid_file "2.pid"
      start_command "ruby ./sample.rb -d --pid 2.pid --log sample2.log"
      stop_command "kill -9 {PID}"

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
      restart_command "kill -2 {PID}" # for this child process
      checks :memory, :below => 300.megabytes, :times => 3
    end
  end
  
  process :event_machine do |p|
    p.pid_file        = 'em.pid'
    p.start_command   = 'ruby em.rb'
    p.stdout          = 'em.log'
    p.daemonize       = true
    p.stop_signals    = [:QUIT, 2.seconds, :KILL]
    
    p.checks :socket, :addr => "tcp://127.0.0.1:33221", :every => 10.seconds, :times => 2, 
                      :timeout => 1.second, :send_data => "ping", :expect_data => /pong/
  end

  process :thin do
    pid_file "thin.pid"
    start_command "bundle exec thin start -R thin.ru -p 33233 -d -l thin.log -P thin.pid"
    stop_signals [:QUIT, 2.seconds, :TERM, 1.seconds, :KILL]

    checks :http, :url => "http://127.0.0.1:33233/hello", :pattern => /World/, :every => 5.seconds, 
                  :times => [2, 3], :timeout => 1.second
  end

end
