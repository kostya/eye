RUBY      = '/usr/local/ruby/1.9.3-p392/bin/ruby'
RAILS_ENV = 'production'
ROOT      = File.expand_path(File.join(File.dirname(__FILE__), %w[ processes ]))
CURRENT   = File.expand_path(File.join(ROOT, %w{current}))
LOGS      = File.expand_path(File.join(ROOT, %w{shared log}))
PIDS      = File.expand_path(File.join(ROOT, %w{shared pids}))

Eye.config do
  logger "#{LOGS}/eye.log"
  logger_level Logger::ERROR
end

Eye.application :super_app do
  env 'RAILS_ENV' => RAILS_ENV
  working_dir ROOT
  trigger :flapping, :times => 10, :within => 1.minute

  process :puma do
    daemonize true
    pid_file "#{PIDS}/puma.pid"
    stdall "#{LOGS}/#{RAILS_ENV}.log"

    start_command "#{RUBY} bin/puma --port 80 --pidfile #{PIDS}/puma.pid --environment #{RAILS_ENV} config.ru"
    stop_command "kill -TERM {{PID}}"
    restart_command "kill -USR2 {{PID}}"

    start_timeout 15.seconds
    stop_grace 10.seconds
    restart_grace 10.seconds

    check :cpu, :every => 30, :below => 80, :times => 3
    check :memory, :every => 30, :below => 70.megabytes, :times => [3,5]
  end
end
