class CustomCheck < Eye::Checker::Custom
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
    checks :custom_check, :times => [1, 3], :below => 80, :every => 2
  end
end
