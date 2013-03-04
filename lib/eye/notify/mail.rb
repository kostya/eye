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
  param :auth, Symbol # :plain, :login, :cram_md5
  
  param :from_mail, String
  
  def execute
    smtp
  end

private  

  def message
    h = []
    h << "From: <#{from_mail || user}>" if from_mail || user
    h << "To: <#{contact}>"
    h << "Subject: <#{message_subject}>"
    h << "Date: #{msg_at.httpdate}"
    h << "Message-Id: <#{rand(1000000000).to_s(36)}.#{$$}.#{contact}>"
    "#{h * "\n"}\n#{message_body}"
  end

  def smtp
    Net::SMTP.start(host, port, domain, user, password, auth) do |smtp|
      smtp.send_message(message, from_mail || user, contact)
    end
  end

end