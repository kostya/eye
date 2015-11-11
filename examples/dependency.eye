# process dependencies example

Eye.app :dependency do
  process(:a) do
    start_command 'sleep 100'
    daemonize true
    pid_file '/tmp/test_process_a.pid'
  end

  process(:b) do
    start_command 'sleep 100'
    daemonize true
    pid_file '/tmp/test_process_b.pid'
    depend_on :a
  end

  process(:c) do
    start_command 'sleep 100'
    daemonize true
    pid_file '/tmp/test_process_c.pid'
    depend_on :a
  end

  process(:d) do
    start_command 'sleep 100'
    daemonize true
    pid_file '/tmp/test_process_d.pid'
    depend_on :b
  end

  process(:e) do
    start_command 'sleep 100'
    daemonize true
    pid_file '/tmp/test_process_e.pid'
    depend_on [:d, :c]
  end
end
