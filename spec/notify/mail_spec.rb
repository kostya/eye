require File.dirname(__FILE__) + '/../spec_helper'

context "Eye::Dsl::Mail" do
  before :each do
    @message = {:message=>"something", :name=>"blocking process", 
      :full_name=>"main:default:blocking process", :pid=>123, 
      :host=>'host1', :level=>:crit, :at => Time.now}
    @opts = {:host=>"mx.some.host", :type=>:mail, :port=>25, :domain=>"some.host", :contact=>"vasya@mail.ru"}
  end

  it "execute" do
    Eye::Notify::Mail.new(@opts, @message)
  end

end