RUBY      = 'ruby'
RAILS_ENV = 'production'

ROOT      = File.expand_path(File.join(File.dirname(__FILE__), %w[ processes ]))

Eye.config do
  logger "#{ROOT}/eye.log"
end

Eye.application :super_app do
  env 'RAILS_ENV' => RAILS_ENV
  working_dir ROOT
  trigger :flapping, :times => 10, :within => 1.minute

  process :puma do
    daemonize true
    pid_file "puma.pid"
    stdall "puma.log"

    start_command "#{RUBY} -S bundle exec puma --port 33280 --environment #{RAILS_ENV} thin.ru"
    stop_command "kill -TERM {{PID}}"
    restart_command "kill -USR2 {{PID}}"

    start_timeout 15.seconds
    stop_grace 10.seconds
    restart_grace 10.seconds

    check :cpu, :every => 30, :below => 80, :times => 3
    check :memory, :every => 30, :below => 70.megabytes, :times => [3,5]
  end
end
