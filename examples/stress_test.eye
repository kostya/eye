# this is not example, just config for eye stress test

PREFIX = ENV['PRE'] || 1

Eye.app :stress_test do
  working_dir "/tmp"

  100.times do |i|
    process "sleep-#{i}" do
      pid_file "sleep-#{PREFIX}-#{i}.pid"
      start_command "sleep 120"
      daemonize true

      checks :cpu, :every => 5.seconds, :below => 10, :times => 5
      checks :memory, :every => 6.seconds, :below => 50.megabytes, :times => 5
    end
  end
end
