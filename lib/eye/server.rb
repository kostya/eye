require 'celluloid/current'
require 'celluloid/io'

class Eye::Server

  include Celluloid::IO

  attr_reader :socket_path, :server

  def initialize(socket_path)
    @socket_path = socket_path
    @server = begin
      UNIXServer.open(socket_path)
    rescue Errno::EADDRINUSE
      unlink_socket_file
      UNIXServer.open(socket_path)
    end
  end

  def run
    loop { async.handle_connection @server.accept }
  end

  def handle_connection(socket)
    text = socket.read

    begin
      # TODO, remove in 1.0

      payload = Marshal.load(text)
      if payload.is_a?(Array)
        cmd, *args = payload
      else
        raise "unknown payload #{payload.inspect}"
      end

    rescue => ex
      # new format
      begin
        pos = text.index("\n")
        msg_size = text[0..pos].to_i
        content = text[pos+1..-1]
        content << socket.read(msg_size - content.length) while content.length < msg_size
        payload = Marshal.load(content)
        cmd = payload[:command]
        args = payload[:args]

      rescue => ex
        error "Failed to read from socket: #{ex.message}"
        return
      end
    end

    response = Eye::Control.command(cmd, *args, {})
    socket.write(Marshal.dump(response))

  rescue Errno::EPIPE
    # client timeouted
    # do nothing

  ensure
    socket.close
  end

  def unlink_socket_file
    File.delete(@socket_path) if @socket_path
  rescue
  end

  finalizer :close_socket

  def close_socket
    @server.close if @server
    unlink_socket_file
  end

end
