cwd = File.expand_path(File.join(File.dirname(__FILE__), %w[ ../ ../ ]))

config_path = File.join(cwd, %w{ config dj.yml } )

workers_count = if File.exists?(config_path)
  YAML.load_file(config_path).try(:[], :workers) || 5
else
  5
end

Eye.application 'delayed_job' do
  working_dir cwd
  stop_on_delete true

  group 'dj' do
    chain grace: 5.seconds

    (1 .. workers_count).each do |i|
      process "dj-#{i}" do
        pid_file "tmp/pids/delayed_job.#{i}.pid"
        start_command "rake jobs:work"
        daemonize true
        stop_signals [:INT, 30.seconds, :TERM, 10.seconds, :KILL]
        stdall "log/dj-#{i}.log"
      end
    end
  end
end
