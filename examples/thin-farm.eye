RUBY = 'ruby'
BUNDLE = 'bundle'

def thin(proxy, port)
  name = "thin-#{port}"

  opts = [
    "-l thins.log",
    "-p #{port}",
    "-P #{name}.pid",
    "-d",
    "-R thin.ru",
    "--tag #{proxy.app.name}.#{proxy.name}",
    "-t 60",
    "-e #{proxy.env["RAILS_ENV"]}",
    "-c #{proxy.working_dir}",
    "-a 127.0.0.1"
  ]

  proxy.process(name) do
    pid_file "#{name}.pid"

    start_command "#{BUNDLE} exec thin start #{opts * ' '}"
    stop_signals [:QUIT, 2.seconds, :TERM, 1.seconds, :KILL]

    stdall "thin.stdall.log"

    checks :http, :url => "http://127.0.0.1:#{port}/hello", :pattern => /World/, 
                  :every => 5.seconds, :times => [2, 3], :timeout => 1.second
  end
end

Eye.app 'thin-farm' do
  working_dir File.expand_path(File.join(File.dirname(__FILE__), %w[ processes ]))
  env "RAILS_ENV" => "production"

  stop_on_delete true # this option means, when we change pids and load config, 
                      # deleted processes will be stops

  triggers :flapping, :times => 10, :within => 1.minute
  checks :memory, :below => 60.megabytes, :every => 30.seconds, :times => 5

  group :web do
    chain :action => :restart, :grace => 5.seconds
    chain :action => :start, :grace => 0.2.seconds

    (5555..5560).each do |port|
      thin self, port
    end
  end

end