# Triggers example:
#
# to execute commands inside trigger need to use 2 methods:
# process.execute_async(cmd, opts), and
# process.execute_sync(cmd, opts)

Eye.config do
  logger "/tmp/eye.log"
end

Eye.app :triggers do

  # Execute shell command before process start
  process :a do
    pid_file "/tmp/a.pid"
    start_command "sleep 100"
    daemonize true

    # send message async which sendxmpp, before process start
    trigger :transition, to: :starting, do: -> {
      process.execute_async "sendxmpp -s 'hhahahaa' someone@jabber.org"
    }
  end

  # Touch some file before process start, remove file after process die
  process :b do
    pid_file "/tmp/b.pid"
    start_command "sleep 100"
    daemonize true

    # before process starting, touch some file
    trigger :transition1, to: :starting, do: -> {
      process.execute_sync "touch /tmp/bla.file"
    }

    # after process, crashed, or stopped, remove that file
    trigger :transition2, to: :down, do: -> {
      process.execute_sync "rm /tmp/bla.file"
    }
  end

  # With restart :c process, send restart to process :a
  process :c do
    pid_file "/tmp/c.pid"
    start_command "sleep 100"
    daemonize true

    app_name = app.name
    trigger :transition, :event => :restarting, :do => ->{
      info "send restarting to :a"
      Eye::Control.command('restart', "#{app_name}:a")
    }
  end

end
