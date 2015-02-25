require File.dirname(__FILE__) + '/../spec_helper'

describe "Eye::Notify::Slack" do
  before :each do
    @time = Time.new 2015, 2, 25, 12
    @message = {:message=>"something", :name=>"blocking process",
        :full_name=>"main:default:blocking process", :pid=>123,
        :host=>'host1', :level=>:crit, :at => @time}
    @h = {:webhook_url=>"https://hooks.slack.com/services/some_token",
      :type=>:slack, :username=>"eye", :contact=>"@channel", :channel => "#default"}
  end

  it "should send slack" do
    require 'slack-notifier'

    @m = Eye::Notify::Slack.new(@h, @message)

    slack = ::Slack::Notifier.new @h[:webhook_url], channel: "#default", username: "eye"
    mock(::Slack::Notifier).new(@h[:webhook_url], channel: "#default", username: "eye"){ slack }

    mock(slack).ping("@channel: *host1* _main:default:blocking process_ at 25 Feb 12:00\n> something") { nil }

    @m.message_body.should == "@channel: *host1* _main:default:blocking process_ at 25 Feb 12:00\n> something"

    @m.execute
  end
end