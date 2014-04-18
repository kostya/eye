require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Notify::Mail" do
  before :each do
    @message = {:message=>"something", :name=>"blocking process",
        :full_name=>"main:default:blocking process", :pid=>123,
        :host=>'host1', :level=>:crit, :at => Time.now}
    @h = {:host=>"mx.some.host.ru", :type=>:mail, :port=>25, :domain=>"some.host", :contact=>"vasya@mail.ru"}
  end

  it "should send mail" do
    @m = Eye::Notify::Mail.new(@h, @message)

    smtp = Net::SMTP.new 'mx.some.host.ru', 25
    mock(Net::SMTP).new('mx.some.host.ru', 25){ smtp }

    ob = ""
    mock(smtp).start('some.host', nil, nil, nil){ ob }

    @m.execute

    @m.message_subject.should == "[host1] [main:default:blocking process] something"
    @m.contact.should == "vasya@mail.ru"

    m = @m.message.split("\n")
    m.should include("To: <vasya@mail.ru>")
    m.should include("Subject: [host1] [main:default:blocking process] something")
  end
end