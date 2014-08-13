require 'net/smtp'

class Eye::Notify::Mail < Eye::Notify

  # Eye.config do
  #   mail :host => "some.host", :port => 12345, :user => "eye@some.host", :password => "123456", :domain => "some.host"
  #   contact :vasya, :mail, "vasya@some.host"
  # end

  param :host, String, true
  param :port, [String, Fixnum], true

  param :domain, String
  param :user, String
  param :password, String
  param :auth, Symbol, nil, nil, [:plain, :login, :cram_md5]

  param :starttls, [TrueClass, FalseClass]

  param :from_mail, String
  param :from_name, String, nil, 'eye'

  def execute
    smtp
  end

  def smtp
    args = [host, port, domain, user, password, auth]
    debug { "called smtp with #{args}" }
    smtp = Net::SMTP.new host, port
    smtp.enable_starttls if starttls

    smtp.start(domain, user, password, auth) do |s|
      s.send_message(message, from_mail || user, contact)
    end
  end

  def message
    h = []
    h << "From: #{from_name} <#{from_mail || user}>" if from_mail || user
    h << "To: <#{contact}>"
    h << "Subject: #{message_subject}"
    h << "Date: #{msg_at.httpdate}"
    h << "Message-Id: <#{rand(1000000000).to_s(36)}.#{$$}.#{contact}>"
    "#{h * "\n"}\n#{message_body}"
  end

end