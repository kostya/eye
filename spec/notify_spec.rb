require File.dirname(__FILE__) + '/spec_helper'

describe "Eye::Notify" do

  context "create notify class" do
    before :each do
      @message = {:message=>"something", :name=>"blocking process", 
        :full_name=>"main:default:blocking process", :pid=>123, 
        :host=>'host1', :level=>:crit, :at => Time.now}

      @config = {
        :mail=>{:host=>"mx.mail.ru", :type => :mail, :port => 25, :domain => "some.host"}, 
        :contacts=>{
          "vasya"=>{:name=>"vasya", :type=>:mail, :contact=>"vasya@mail.ru", :opts=>{}}, 
          "petya"=>{:name=>"petya", :type=>:mail, :contact=>"petya@mail.ru", :opts=>{:port=>1111}}, 
          'idiots'=>[{:name=>"idiot1", :type=>:mail, :contact=>"idiot1@mail.ru", :opts=>{}}, {:name=>"idiot2", :type=>:mail, :contact=>"idiot2@mail.ru", :opts=>{:port=>1111}}], 
          "idiot1"=>{:name=>"idiot1", :type=>:mail, :contact=>"idiot1@mail.ru", :opts=>{}}, 
          "idiot2"=>{:name=>"idiot2", :type=>:mail, :contact=>"idiot2@mail.ru", :opts=>{:port=>1111}},
          "idiot3"=>{:name=>"idiot3", :type=>:jabber, :contact=>"idiot3@mail.ru", :opts=>{:host => "jabber.some.host", :port=>1111, :user => "some_user"}}}}

      stub(Eye::Control).current_config{ {:config => @config} }
    end

    it "should create right class" do
      h = {:host=>"mx.mail.ru", :type=>:mail, :port=>25, :domain=>"some.host", :contact=>"vasya@mail.ru"}
      mock(Eye::Notify::Mail).new(h, @message)
      Eye::Notify.notify('vasya', @message)
    end

    it "should create right class with additional options" do
      h = {:host=>"mx.mail.ru", :type=>:mail, :port=>1111, :domain=>"some.host", :contact=>"petya@mail.ru"}
      mock(Eye::Notify::Mail).new(h, @message)
      Eye::Notify.notify('petya', @message)
    end

    it "should create right class with group of contacts" do
      h1 = {:host=>"mx.mail.ru", :type=>:mail, :port=>25, :domain=>"some.host", :contact=>"idiot1@mail.ru"}
      h2 = {:host=>"mx.mail.ru", :type=>:mail, :port=>1111, :domain=>"some.host", :contact=>"idiot2@mail.ru"}
      mock(Eye::Notify::Mail).new(h1, @message)
      mock(Eye::Notify::Mail).new(h2, @message)
      Eye::Notify.notify('idiots', @message)
    end

    it "without contact should do nothing" do
      dont_allow(Eye::Notify::Mail).new
      Eye::Notify.notify('noperson', @message)
    end

    it "should also notify to jabber" do
      h = {:host=>"jabber.some.host", :port=>1111, :user=>"some_user", :contact=>"idiot3@mail.ru"}
      mock(Eye::Notify::Jabber).new(h, @message)
      Eye::Notify.notify('idiot3', @message)
    end
  end

end