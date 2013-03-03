require 'net/smtp'

class Eye::Notify::Mail < Eye::Notify

  # Eye.config do
  #   mail :host => "some.host", :port => 12345, :user => "eye@some.host", :password => "123456", :domain => "some.host"
  #   contact :vasya, :mail, "vasya@some.host"
  # end

  param :host, String, true
  param :port, [String, Fixnum], true
  param :user, String
  param :password, String
  param :domain, String
  param :from, String

  def execute
    smtp
  end

private  

  def message
    <<-M
From: #{from_name} <#{from_email}>
To: #{to_name || name} <#{to_email}>
Subject: [Eye] #{subject}
Date: #{@message_h[:at].httpdate}
Message-Id: <#{rand(1000000000).to_s(36)}.#{$$}.#{from_email}>

#{super}
    M
  end

  def smtp
    Net::SMTP.start(host, port) do |smtp|
      smtp.send_message(message, from || user, contact)
    end
  end

end