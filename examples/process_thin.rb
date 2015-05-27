
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
    "-e #{proxy.env['RAILS_ENV']}",
    "-c #{proxy.working_dir}",
    "-a 127.0.0.1"
  ]

  proxy.process(name) do
    pid_file "#{name}.pid"

    start_command "#{BUNDLE} exec thin start #{opts * ' '}"
    stop_signals [:QUIT, 2.seconds, :TERM, 1.seconds, :KILL]

    stdall "thin.stdall.log"

    check :http, :url => "http://127.0.0.1:#{port}/hello", :pattern => /World/,
                 :every => 5.seconds, :times => [2, 3], :timeout => 1.second
  end
end
