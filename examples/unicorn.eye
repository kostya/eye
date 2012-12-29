Eye.application "test_unicorn" do
  env "RAILS_ENV" => "production"
  working_dir "/projects/test_unicorn"
  ruby = '/usr/local/ruby/1.9.3/bin/ruby'

  process("unicorn") do
    env "PATH" => "/usr/local/ruby/1.9.3/bin/:#{ENV['PATH']}"
    pid_file "/projects/cap/test_unicorn/shared/tmp/pids/unicorn.pid"
    start_command "#{ruby} ./bin/unicorn -Dc ./config/unicorn.rb -E production"
    stop_command "kill -QUIT {{PID}}"
    restart_command "kill -USR2 {{PID}}"
    stdall "log/unicorn.log"

    checks :cpu, :every => 30, :below => 80, :times => 3
    checks :memory, :every => 30, :below => 150.megabytes, :times => [3,5]

    start_timeout 30.seconds
    stop_grace 5.seconds
    restart_grace 10.seconds

    monitor_children do
      stop_command "kill -QUIT {{PID}}"
      checks :cpu, :every => 30, :below => 80, :times => 3
      checks :memory, :every => 30, :below => 150.megabytes, :times => [3,5]
    end
  end

end
