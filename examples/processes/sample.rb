require 'optparse'

# This hash will hold all of the options
# parsed from the command-line by
# OptionParser.
options = {}

optparse = OptionParser.new do |opts|
  # This displays the help screen, all programs are
  # assumed to have this option.
  opts.on('-h', '--help', 'Display this screen') do
    puts opts
    exit
  end

  opts.on('-p', '--pid FILE', 'pid_file') do |a|
    options[:pid_file] = a
  end

  opts.on('-l', '--log FILE', 'log_file') do |a|
    options[:log_file] = a
  end

  opts.on('-L', '--lock FILE', 'lock_file') do |a|
    options[:lock_file] = a
  end

  opts.on('-d', '--daemonize', 'Daemonize') do
    options[:daemonize] = true
  end

  opts.on('-s', '--daemonize_delay DELAY', 'Daemonized time') do |d|
    options[:daemonize_delay] = d
  end

  opts.on('-r', '--raise', 'Raised execution') do
    options[:raise] = true
  end

  opts.on('-w', '--watch_file FILE', 'Exit on touched file') do |w|
    options[:watch_file] = w
  end

  opts.on('-W', '--watch_file_delay DELAY', 'Exit on touched file, after delay') do |w|
    options[:watch_file_delay] = w
  end
end

optparse.parse!

module Sample

  def puts(mes = '')
    tm = Time.now
    STDOUT.puts "#{tm} (#{tm.to_f}) - #{mes}"
    STDOUT.flush
  end

  def daemonize(pid_file, log_file, daemonize_delay = 0)
    puts "daemonize start #{pid_file}, #{log_file}, #{daemonize_delay}"

    if daemonize_delay && daemonize_delay.to_f > 0
      puts "daemonize delay start #{daemonize_delay}"
      sleep daemonize_delay.to_f
      puts 'daemonize delay end'
    end

    daemon
    STDOUT.reopen(log_file, 'a')
    STDERR.reopen(log_file, 'a')
    File.open(pid_file, 'w') { |f| f.write $$.to_s }

    puts 'daemonized'
  end

  def daemon
    exit if fork                     # Parent exits, child continues.
    Process.setsid                   # Become session leader.
    exit if fork                     # Zap session leader. See [1].

    STDIN.reopen '/dev/null'         # Free file descriptors and
    STDOUT.reopen '/dev/null', 'a'   # point them somewhere sensible.
    STDERR.reopen '/dev/null', 'a'
    0
  end

end

extend Sample

if options[:daemonize]
  daemonize(options[:pid_file], options[:log_file], options[:daemonize_delay])
end

puts "Started #{ARGV.inspect}, #{options.inspect}, #{ENV['ENV1']}"

if options[:lock_file]
  if File.exist?(options[:lock_file])
    puts 'Lock file exists, exiting'
    exit 1
  else
    File.open(options[:lock_file], 'w') { |f| f.write $$ }
  end
end

if options[:raise]
  puts 'Raised'
  File.unlink(options[:lock_file]) if options[:lock_file]
  exit 1
end

trap('USR1') do
  puts 'USR1 signal!'
end

trap('USR2') do
  puts 'USR2 start memory leak'
  ar = []
  300_000.times { |i| ar << "memory leak #{i}" * 10 }
end

def check_watch_file(options)
  return unless options[:watch_file] && File.exist?(options[:watch_file])

  puts 'watch file finded'
  File.unlink(options[:watch_file])

  if options[:watch_file_delay]
    puts 'watch_file delay start'
    sleep options[:watch_file_delay].to_f
    puts 'watch_file delay end'
  end

  true
end

loop do
  sleep 0.1
  puts 'tick'
  break if check_watch_file(options)
end

puts 'exit'
File.unlink(options[:lock_file]) if options[:lock_file]
exit 0
