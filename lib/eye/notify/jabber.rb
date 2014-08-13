require 'xmpp4r'

class Eye::Notify::Jabber < Eye::Notify

  # Eye.config do
  #   jabber :host => "some.host", :port => 12345, :user => "eye@some.host", :password => "123456"
  #   contact :vasya, :jabber, "vasya@some.host"
  # end

  param :host, String, true
  param :port, [String, Fixnum], true
  param :user, String, true
  param :password, String

  def execute
    debug { "send jabber #{[host, port, user, password]} - #{[contact, message_body]}" }

    mes = ::Jabber::Message.new(contact, message_body)
    mes.set_type(:normal)
    mes.set_id('1')
    mes.set_subject(message_subject)

    client = ::Jabber::Client.new(::Jabber::JID.new("#{user}/Eye"))
    client.connect(host, port)
    client.auth(password)
    client.send(mes)
    client.close
  end

end