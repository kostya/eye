# Example: how to run sidekiq daemon

module Eye
  module Sidekiq
    def sidekiq_process(name)
      rails_env = env['RAILS_ENV']
    
      process(name) do
        start_command "bin/sidekiq -e #{rails_env} -C ./config/sidekiq.#{rails_env}.yml"
        pid_file "tmp/pids/#{name}.pid"
        stdall "log/#{name}.log"
        daemonize true
        stop_signals [:USR1, 0, :TERM, 10.seconds, :KILL]
    
        check :cpu, :every => 30, :below => 100, :times => 5
        check :memory, :every => 30, :below => 300.megabytes, :times => 5
      end
    end
  end
end

Eye.application :sidekiq_test do
  extend Eye::Sidekiq
  
  working_dir File.expand_path(File.join(File.dirname(__FILE__), %w[ processes ]))
  env "RAILS_ENV" => 'production'

  sidekiq_process :sidekiq
end
