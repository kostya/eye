# Example: how to run sidekiq daemon

def sidekiq_process(proxy, name)
  rails_env = proxy.env['RAILS_ENV']

  proxy.process(name) do
    start_command "ruby ./bin/sidekiq -e #{rails_env} -C ./config/sidekiq.#{rails_env}.yml"
    pid_file "tmp/pids/#{name}.pid"
    stdall "log/#{name}.log"
    daemonize true
    stop_signals [:QUIT, 5.seconds, :TERM, 5.seconds, :KILL]
    
    checks :cpu, :every => 30, :below => 100, :times => 5
    checks :memory, :every => 30, :below => 300.megabytes, :times => 5
  end
end

Eye.application :sidekiq_test do
  working_dir '/some_dir'
  env "RAILS_ENV" => 'production'
 
  sidekiq_process self, :sidekiq
end