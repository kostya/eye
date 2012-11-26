require 'socket'
require 'celluloid'
require 'celluloid/io'
require_relative 'io/unix_socket'
require_relative 'io/unix_server'

class Eye::Server
  include Celluloid::IO
  
  attr_reader :socket_path, :server
  
  def initialize(socket_path)
    @socket_path = socket_path
    @server = UNIXServer.open(socket_path)
  end
  
  def finalize
    @server.close if @server
    unlink_socket_file
  end

  def run
    loop { handle_connection! @server.accept }
  end

  def handle_connection(socket)
    command, *args = socket.readline.strip.split(':')
    response = command(command, *args)
    socket.write(Marshal.dump(response))
  ensure
    socket.close
  end

  def command(cmd, *args)
    Eye::controller.command(cmd, *args)
  end

  def unlink_socket_file
    File.delete(@socket_path) if @socket_path
  rescue
  end

end