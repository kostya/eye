# process dependencies :b -> :a

Eye.app :dependency do
  process(:a) do
    start_command "sleep 100"
    daemonize true
    pid_file "/tmp/test_process_a.pid"
  end

  process(:b) do
    start_command "sleep 100"
    daemonize true
    pid_file "/tmp/test_process_b.pid"
    depend_on :a
  end

end
