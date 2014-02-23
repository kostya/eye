BUNDLE = 'bundle'
RAILS_ENV = 'production'
ROOT = File.expand_path(File.join(File.dirname(__FILE__), %w[ processes ]))

Eye.config do
  logger "#{ROOT}/eye.log"
end

Eye.application :puma do
  env 'RAILS_ENV' => RAILS_ENV
  working_dir ROOT
  trigger :flapping, :times => 10, :within => 1.minute

  process :puma do
    daemonize true
    pid_file "puma.pid"
    stdall "puma.log"

    start_command "#{BUNDLE} exec puma --port 33280 --environment #{RAILS_ENV} thin.ru"
    stop_signals [:TERM, 5.seconds, :KILL]
    restart_command "kill -USR2 {PID}"

    restart_grace 10.seconds # just sleep this until process get up status
                             # (maybe enought to puma soft restart)

    check :cpu, :every => 30, :below => 80, :times => 3
    check :memory, :every => 30, :below => 70.megabytes, :times => [3,5]
  end
end
