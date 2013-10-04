class Cpu9 < Eye::Checker::Custom
  param :below, [Fixnum, Float], true

  def initialize(*args)
    super
    @a = [true, true, false, false, false]
  end

  def get_value
    @a.shift
  end

  def good?(value)
    value
  end
end

Eye.application("bla") do
  working_dir File.expand_path(File.join(File.dirname(__FILE__), %w[.]))
  process("1") do
    pid_file "1.pid"
    start_command "sleep 30"
    daemonize true
    checks :cpu, :below => 100, :times => 3, :every => 10
    checks :cpu9, :below => 100, :times => 3, :every => 10
    checks :cpu3, :below => 100, :times => 3, :every => 10
    checks :cpu_4, :below => 100, :times => 3, :every => 10
  end
end
