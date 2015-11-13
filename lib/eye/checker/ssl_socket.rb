require 'openssl'

class Eye::Checker::SslSocket < Eye::Checker::Socket

  # ctx params from http://ruby-doc.org/stdlib-1.9.3/libdoc/openssl/rdoc/OpenSSL/SSL/SSLContext.html
  #
  # examples:
  #
  #   check :ssl_socket, :addr => "tcp://127.0.0.1:443", :every => 5.seconds, :times => 1, :timeout => 1.second,
  #     :ctx => {ssl_version: :SSLv23, verify_mode: OpenSSL::SSL::VERIFY_NONE}
  #

  param :ctx, Hash, nil, ssl_version: :SSLv23, verify_mode: OpenSSL::SSL::VERIFY_NONE

private

  def open_socket
    OpenSSL::SSL::SSLSocket.new(super, ctx_params).tap do |socket|
      socket.sync_close = true
      socket.connect
    end
  end

  def ctx_params
    @ctx_params ||= OpenSSL::SSL::SSLContext.new.tap { |c| c.set_params(ctx) }
  end

end
