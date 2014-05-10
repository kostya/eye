# b -> a

Eye.app :dependency do
  process(:a) do
    start_command "sleep 100"
    daemonize true
    pid_file "/tmp/test_process_a.pid"

    trigger :check_dependency, :names => %w{ b }
  end

  process(:b) do
    start_command "sleep 100"
    daemonize true
    pid_file "/tmp/test_process_b.pid"

    trigger :wait_dependency, :names => %w{ a }
  end

end
