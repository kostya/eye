        Eye.app :app do
          working_dir "/tmp/"
          start_grace 0.5
          check_alive_period 0.5
          trigger :flapping, :times => 3, :within => 5.seconds, :retry_in => 1.hour

          process(:a) do
            start_command "asdfsdf asdf asdf as"
            daemonize true
            pid_file "1.pid"
          end

          process(:b) do
            start_command "sleep 100"
            daemonize true
            pid_file "2.pid"
            depend_on :a
          end

        end

