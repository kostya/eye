Eye
===

Process monitoring tool. With bluepill-like config syntax. Requires ruby >= 1.9.2. Uses Celluloid and Celluloid::IO.

Recommended installation on the server (system wide):

    $ sudo /usr/local/ruby/1.9.3/bin/gem install eye
    $ sudo ln -sf /usr/local/ruby/1.9.3/bin/eye /usr/local/bin/eye

Config example, shows most of the options (examples/test.eye):

```ruby
Eye.load("./eye/*.rb") # load submodules
Eye.logger = "/tmp/eye.log" # eye logger

Eye.app "test" do
  working_dir File.expand_path(File.join(File.dirname(__FILE__), %w[ processes ]))
  stdall "trash.log" # stdout + stderr
  env "APP_ENV" => "production"

  group "samples" do
    env "A" => "1" # env merging
    chain :grace => 5.seconds, :action => :restart # restarting with 5s interval, one by one.

    # eye daemonized process
    process("sample1") do
      pid_file "1.pid" # expanded with working_dir
      start_command "ruby ./sample.rb"
      daemonize true
      stdall "sample1.log"

      checks :cpu, :below => 30, :times => [3, 5]
    end

    # self daemonized process
    process("sample2") do
      pid_file "2.pid"
      start_command "ruby ./sample.rb -d --pid 2.pid --log sample2.log"
      stop_command "kill -9 {{PID}}"

      checks :memory, :below => 300.megabytes, :times => 3
    end
  end

  # daemon with 3 childs
  process("forking") do
    pid_file "forking.pid"
    start_command "ruby ./forking.rb start"
    stop_command "ruby forking.rb stop"
    stdall "forking.log"

    start_timeout 5.seconds
    stop_grace 5.seconds
  
    monitor_children do
      childs_update_period 5.seconds

      restart_command "kill -2 {{PID}}"
      checks :memory, :below => 300.megabytes, :times => 3
    end
  end

end
```

## Start and/or load config:

    $ eye load examples/test.eye

### Status: 
  
    $ eye i(nfo)

```
test                                       
  samples                                  
    sample1 ....................... (5151) : up (22:38, 1%, 22Mb)
    sample2 ....................... (5183) : up (22:38, 0%, 21Mb)
  forking ......................... (4866) : up (22:37, 0%, 21Mb)
    =child= ....................... (4869) : up (22:37, 0%, 22Mb)
    =child= ....................... (4872) : up (22:37, 0%, 22Mb)
    =child= ....................... (4875) : up (22:37, 0%, 22Mb)
```
