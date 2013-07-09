require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Notify::Jabber" do
  before :each do
    @message = {:message=>"something", :name=>"blocking process",
        :full_name=>"main:default:blocking process", :pid=>123,
        :host=>'host1', :level=>:crit, :at => Time.now}
    @h = {:host=>"mx.some.host.ru", :type=>:mail, :port=>25, :contact=>"vasya@mail.ru", :password => "123"}
  end

  it "should send jabber" do
    require 'xmpp4r'

    @m = Eye::Notify::Jabber.new(@h, @message)

    ob = ""
    mock(Jabber::Client).new(anything){ ob }
    mock(ob).connect('mx.some.host.ru', 25)
    mock(ob).auth('123')
    mock(ob).send(is_a(Jabber::Message))
    mock(ob).close

    @m.execute
  end
end