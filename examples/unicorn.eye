# Example: now to run unicorn, and monitor its child processes

RUBY = '/usr/local/ruby/1.9.3/bin/ruby' # ruby on the server
RAILS_ENV = 'production'

Eye.application "rails_unicorn" do
  env "RAILS_ENV" => RAILS_ENV

  # unicorn requires to be `ruby` in path (for soft restart)
  env "PATH" => "#{File.dirname(RUBY)}:#{ENV['PATH']}"

  working_dir File.expand_path(File.join(File.dirname(__FILE__), %w[ processes ]))

  process("unicorn") do
    pid_file "tmp/pids/unicorn.pid"
    start_command "#{RUBY} ./bin/unicorn -Dc ./config/unicorn.rb -E #{RAILS_ENV}"
    stdall "log/unicorn.log"

    # stop signals:
    # http://unicorn.bogomips.org/SIGNALS.html
    stop_signals [:TERM, 10.seconds]

    # soft restart
    restart_command "kill -USR2 {PID}"

    check :cpu, :every => 30, :below => 80, :times => 3
    check :memory, :every => 30, :below => 150.megabytes, :times => [3,5]

    start_timeout 100.seconds
    restart_grace 30.seconds

    monitor_children do
      stop_command "kill -QUIT {PID}"
      check :cpu, :every => 30, :below => 80, :times => 3
      check :memory, :every => 30, :below => 150.megabytes, :times => [3,5]
    end
  end

end
