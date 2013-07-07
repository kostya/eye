require 'bundler/setup'
require 'eventmachine'

def answer(data)
  case data
    when 'ping' then "pong\n"
    when 'bad' then "what\n"
    when 'timeout' then sleep 5; "ok\n"
    when 'exception' then raise 'haha'
    when 'quit' then EM.stop
    when 'big' then 'a' * 10_000_000
  end
end

class Echo < EM::Connection
  def post_init
    puts "-- someone connected to the echo server!"
  end

  def receive_data data
    puts "receive #{data.inspect}"
    send_data(answer(data))
  end

  def unbind
     puts "-- someone disconnected from the echo server!"
  end
end

class EchoObj < EM::Connection
  include EM::P::ObjectProtocol

  def post_init
    puts "-- someone connected to the echo server!"
  end

  def receive_object obj # {:command => 'ping'}
    puts "receive #{obj.inspect}"
    send_object(answer(obj[:command]).chop)
  end

  def unbind
    puts "-- someone disconnected from the echo server!"
  end
end

trap "TERM" do
  EM.stop
  `rm /tmp/em_test_sock_spec` rescue nil
end

EM.run do
  EM.start_server '127.0.0.1', 33231, Echo
  EM.start_server '127.0.0.1', 33232, EchoObj
  EM.start_server "/tmp/em_test_sock_spec", nil, Echo
  puts 'started'
end
