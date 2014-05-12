require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Dsl notify" do
  it "integration" do
    conf = <<-E
      Eye.config do
        mail :host => "mx.some.host.ru", :port => 25

        contact :vasya, :mail, "vasya@mail.ru"
        contact :petya, :mail, "petya@mail.ru", :port => 1111

        contact_group :idiots do
          contact :idiot1, :mail, "idiot1@mail.ru"
          contact :idiot2, :mail, "idiot1@mail.ru", :port => 1111
        end
      end

      Eye.application :bla do
        notify :vasya
        notify :idiots, :fatal

        group :gr1 do
          notify :petya
          notify :idiot1, :info
        end
      end
    E
    res = Eye::Dsl.parse(conf).to_h

    res.should == {
      :applications => {
        "bla"=>{:name=>"bla",
          :notify=>{"vasya"=>:warn, "idiots"=>:fatal},
          :groups=>{"gr1"=>{:name=>"gr1",
            :notify=>{"vasya"=>:warn, "idiots"=>:fatal, "petya"=>:warn, "idiot1"=>:info}, :application=>"bla"}}}},
      :settings => {
        :mail=>{:host=>"mx.some.host.ru", :port => 25, :type => :mail},
        :contacts=>{
          "vasya"=>{:name=>"vasya", :type=>:mail, :contact=>"vasya@mail.ru", :opts=>{}},
          "petya"=>{:name=>"petya", :type=>:mail, :contact=>"petya@mail.ru", :opts=>{:port=>1111}},
          'idiots'=>[{:name=>"idiot1", :type=>:mail, :contact=>"idiot1@mail.ru", :opts=>{}}, {:name=>"idiot2", :type=>:mail, :contact=>"idiot1@mail.ru", :opts=>{:port=>1111}}],
          "idiot1"=>{:name=>"idiot1", :type=>:mail, :contact=>"idiot1@mail.ru", :opts=>{}},
          "idiot2"=>{:name=>"idiot2", :type=>:mail, :contact=>"idiot1@mail.ru", :opts=>{:port=>1111}}}}}
  end

  it "valid contact type" do
    conf = <<-E
      Eye.config do
        contact :vasya, :mail, "vasya@mail.ru", :port => 25, :host => "localhost"
      end
    E
    Eye::Dsl.parse(conf).settings.should == {:contacts=>{
      "vasya"=>{:name=>"vasya", :type=>:mail, :contact=>"vasya@mail.ru", :opts=>{:port => 25, :host => "localhost"}}}}
  end

  it "raise on unknown contact type" do
    conf = <<-E
      Eye.config do
        contact :vasya, :dddd, "vasya@mail.ru", :host => "localhost", :port => 12
      end
    E
    expect{ Eye::Dsl.parse(conf) }.to raise_error(Eye::Dsl::Error)
  end

  it "raise on unknown additional_options" do
    conf = <<-E
      Eye.config do
        contact :vasya, :mail, "vasya@mail.ru", :host => "localhost", :port => 12, :bla => 1
      end
    E
    expect{ Eye::Dsl.parse(conf) }.to raise_error(Eye::Dsl::Validation::Error)
  end

  it "raise on not including on list of values" do
    conf = <<-E
      Eye.config do
        contact :vasya, :mail, "vasya@mail.ru", :host => "localhost", :port => 12, :auth => :ply
      end
    E
    expect{ Eye::Dsl.parse(conf) }.to raise_error(Eye::Dsl::Validation::Error)
  end

  it "set notify inherited" do
    conf = <<-E
      Eye.app :bla do
        notify :vasya

        group :bla do
        end
      end
    E
    Eye::Dsl.parse_apps(conf).should == {
      "bla" => {:name=>"bla",
        :notify=>{"vasya"=>:warn},
        :groups=>{"bla"=>{:name=>"bla",
          :notify=>{"vasya"=>:warn}, :application=>"bla"}}}}
  end

  it "raise on unknown level" do
    conf = <<-E
      Eye.app :bla do
        notify :vasya, :petya
      end
    E
    expect{ Eye::Dsl.parse(conf) }.to raise_error(Eye::Dsl::Error)
  end

  it "clear notify with nonotify" do
    conf = <<-E
      Eye.app :bla do
        notify :vasya, :warn

        group :bla do
          nonotify :vasya
        end
      end
    E
    Eye::Dsl.parse_apps(conf).should == {
      "bla" => {:name=>"bla",
        :notify=>{"vasya"=>:warn},
        :groups=>{"bla"=>{:name=>"bla", :notify=>{}, :application=>"bla"}}}}
  end

  it "add custom notify" do
    conf = <<-E
      class Cnot < Eye::Notify::Custom
        param :bla, String
      end

      Eye.config do
        cnot :bla => "some"
        contact :vasya, :cnot, "some"
      end

      Eye.application :bla do
        notify :vasya
      end
    E
    res = Eye::Dsl.parse(conf).to_h

    res.should == {:applications => {"bla"=>{:name=>"bla", :notify=>{"vasya"=>:warn}}},
       :settings => {:cnot=>{:bla=>"some", :type=>:cnot}, :contacts=>{"vasya"=>{:name=>"vasya", :type=>:cnot, :contact=>"some", :opts=>{}}}}}
  end
end