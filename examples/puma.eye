RUBY    = '/usr/local/ruby/1.9.3-p392/bin/ruby'
ENV     = 'production'
ROOT    = '/var/www/super_app'
CURRENT = File.expand_path(File.join(ROOT, %w{current}))
SHARED  = File.expand_path(File.join(ROOT, %w{shared}))
LOGS    = File.expand_path(File.join(ROOT, %w{shared log}))
PIDS    = File.expand_path(File.join(ROOT, %w{shared pids}))

Eye.config do
  logger "#{LOGS}/eye.log"
  logger_level Logger::ERROR
end

Eye.application :super_app do
  env 'RAILS_ENV' => ENV
  working_dir CURRENT
  triggers :flapping, :times => 10, :within => 1.minute

  process :puma do
    daemonize true
    pid_file "#{PIDS}/puma.pid"
    stdall "#{LOGS}/#{ENV}.log"

    start_command "#{RUBY} #{CURRENT}/bin/puma --port 80 --pidfile #{PIDS}/puma.pid --environment #{ENV} #{CURRENT}/config.ru"
    stop_command "kill -TERM {{PID}}"
    restart_command "kill -USR2 {{PID}}"

    start_timeout 15.seconds
    stop_grace 10.seconds
    restart_grace 10.seconds

    checks :cpu, :every => 30, :below => 80, :times => 3
    checks :memory, :every => 30, :below => 70.megabytes, :times => [3,5]
  end
end
