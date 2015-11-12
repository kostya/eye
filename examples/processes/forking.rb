require 'bundler/setup'
require 'forking'

root = File.expand_path(File.dirname(__FILE__))
cnt = (ENV['FORKING_COUNT'] || 3).to_i

f = Forking.new(name: 'forking', working_dir: root,
                log_file: "#{root}/forking.log",
                pid_file: "#{root}/forking.pid", sync_log: true)

cnt.times do |i|
  f.spawn(log_file: "#{root}/child#{i}.log", sync_log: true) do
    $0 = 'forking child'
    t = 0
    loop do
      p "#{Time.now} - #{Time.now.to_f} - #{i} - tick"
      sleep 0.1
      t += 0.1
      exit if t > 300
    end
  end
end

f.run!
