Eye
===
[![Gem Version](https://badge.fury.io/rb/eye.png)](http://rubygems.org/gems/eye)
[![Build Status](https://secure.travis-ci.org/kostya/eye.png?branch=master)](http://travis-ci.org/kostya/eye)
[![Coverage Status](https://coveralls.io/repos/kostya/eye/badge.png?branch=master)](https://coveralls.io/r/kostya/eye?branch=master)

Process monitoring tool. Inspired from Bluepill and God. Requires Ruby(MRI) >= 1.9.3-p194. Uses Celluloid and Celluloid::IO.

Little demo, shows general commands and how chain works:

[![Eye](https://raw.github.com/kostya/stuff/master/eye/eye.png)](https://raw.github.com/kostya/stuff/master/eye/eye.gif)

Recommended installation on the server (system wide):

    $ sudo /usr/local/ruby/1.9.3/bin/gem install eye
    $ sudo ln -sf /usr/local/ruby/1.9.3/bin/eye /usr/local/bin/eye


###  Why?

We have used god and bluepill in production and always ran into bugs (segfaults, crashes, lost processes, kill not-related processes, load problems, deploy problems, ...)

We wanted something more robust and production stable.

We wanted the features of bluepill and god, with a few extras like chains, nested configuring, mask matching, easy debug configs

I hope we've succeeded, we're using eye in production and are quite happy.

###  Config example

examples/test.eye
```ruby
# load submodules, here just for example
Eye.load('./eye/*.rb')

# Eye self-configuration section
Eye.config do
  logger '/tmp/eye.log'
end

# Adding application
Eye.application 'test' do
  # All options inherits down to the config leafs.
  # except `env`, which merging down

  working_dir File.expand_path(File.join(File.dirname(__FILE__), %w[ processes ]))
  stdall 'trash.log' # stdout,err logs for processes by default
  env 'APP_ENV' => 'production' # global env for each processes
  trigger :flapping, times: 10, within: 1.minute, retry_in: 10.minutes
  check :cpu, every: 10.seconds, below: 100, times: 3 # global check for all processes

  group 'samples' do
    chain grace: 5.seconds # chained start-restart with 5s interval, one by one.

    # eye daemonized process
    process :sample1 do
      pid_file '1.pid' # pid_path will be expanded with the working_dir
      start_command 'ruby ./sample.rb'

      # when no stop_command or stop_signals, default stop is [:TERM, 0.5, :KILL]
      # default `restart` command is `stop; start`

      daemonize true
      stdall 'sample1.log'

      # ensure the CPU is below 30% at least 3 out of the last 5 times checked
      check :cpu, below: 30, times: [3, 5]
    end

    # self daemonized process
    process :sample2 do
      pid_file '2.pid'
      start_command 'ruby ./sample.rb -d --pid 2.pid --log sample2.log'
      stop_command 'kill -9 {PID}'

      # ensure the memory is below 300Mb the last 3 times checked
      check :memory, every: 20.seconds, below: 300.megabytes, times: 3
    end
  end

  # daemon with 3 children
  process :forking do
    pid_file 'forking.pid'
    start_command 'ruby ./forking.rb start'
    stop_command 'ruby forking.rb stop'
    stdall 'forking.log'

    start_timeout 10.seconds
    stop_timeout 5.seconds

    monitor_children do
      restart_command 'kill -2 {PID}' # for this child process
      check :memory, below: 300.megabytes, times: 3
    end
  end

  # eventmachine process, daemonized with eye
  process :event_machine do |p|
    pid_file 'em.pid'
    start_command 'ruby em.rb'
    stdout 'em.log'
    daemonize true
    stop_signals [:QUIT, 2.seconds, :KILL]

    check :socket, addr: 'tcp://127.0.0.1:33221', every: 10.seconds, times: 2,
                   timeout: 1.second, send_data: 'ping', expect_data: /pong/
  end

  # thin process, self daemonized
  process :thin do
    pid_file 'thin.pid'
    start_command 'bundle exec thin start -R thin.ru -p 33233 -d -l thin.log -P thin.pid'
    stop_signals [:QUIT, 2.seconds, :TERM, 1.seconds, :KILL]

    check :http, url: 'http://127.0.0.1:33233/hello', pattern: /World/,
                 every: 5.seconds, times: [2, 3], timeout: 1.second
  end

end
```

### Start eye daemon and/or load config:

    $ eye l(oad) examples/test.eye

load folder with configs:

    $ eye l examples/
    $ eye l examples/*.rb

foreground load:

    $ eye l CONF -f

If the eye daemon has already started and you call the `load` command, the config will be updated (into eye daemon). New objects(applications, groups, processes) will be added and monitored. Processes removed from the config will be removed (and stopped if the process has `stop_on_delete true`). Other objects will update their configs.


Process statuses:

    $ eye i(nfo)

```
test
  samples
    sample1 ....................... up  (21:52, 0%, 13Mb, <4107>)
    sample2 ....................... up  (21:52, 0%, 12Mb, <4142>)
  event_machine ................... up  (21:52, 3%, 26Mb, <4112>)
  forking ......................... up  (21:52, 0%, 41Mb, <4203>)
    child-4206 .................... up  (21:52, 0%, 41Mb, <4206>)
    child-4211 .................... up  (21:52, 0%, 41Mb, <4211>)
    child-4214 .................... up  (21:52, 0%, 41Mb, <4214>)
  thin ............................ up  (21:53, 2%, 54Mb, <4228>)
```

### Commands:

    start, stop, restart, delete, monitor, unmonitor

Command params (with restart for example):

    $ eye r(estart) all
    $ eye r test
    $ eye r samples
    $ eye r sample1
    $ eye r sample*
    $ eye r test:samples
    $ eye r test:samples:sample1
    $ eye r test:samples:sample*
    $ eye r test:*sample*

Check config syntax:

    $ eye c(heck) examples/test.eye

Config explain (for debug):

    $ eye e(xplain) examples/test.eye

Log tracing (tail and grep):

    $ eye t(race)
    $ eye t test
    $ eye t sample

Quit monitoring:

    $ eye q(uit)
    $ eye q -s # stop all processes and quit

Interactive info:

    $ eye w(atch)

Process statuses history:

    $ eye hi(story)

Eye daemon info:

    $ eye x(info)
    $ eye x -c # for show current config

Process states and events:

[![Eye](https://raw.github.com/kostya/stuff/master/eye/mprocess.png)](https://raw.github.com/kostya/stuff/master/eye/process.png)


[Eye related projects](https://github.com/kostya/eye/wiki/Related-projects)

[Articles](https://github.com/kostya/eye/wiki/Articles)

[Using Env variables](https://github.com/kostya/eye/wiki/Using-ENV-variables-in-config)


Thanks `Bluepill` for the nice config ideas.
